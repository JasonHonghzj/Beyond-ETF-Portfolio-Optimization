# Shared, chronological next-close forecasting for the presentation's RF/XGB models.
# Each row uses the previous `lookback` closes, never the target day's close.

.model_integer <- function(value, name, minimum = 1L) {
  if (length(value) != 1L || !is.numeric(value) || is.na(value) ||
      !is.finite(value) || value != floor(value) || value < minimum ||
      value > .Machine$integer.max) {
    stop(name, " must be an integer >= ", minimum, ".", call. = FALSE)
  }
  as.integer(value)
}

make_lagged_data <- function(prices, lookback = 20L) {
  lookback <- .model_integer(lookback, "lookback")
  if (!is.data.frame(prices) || !all(c("date", "close") %in% names(prices))) {
    stop("prices must be a data frame with date and close columns.", call. = FALSE)
  }
  dates <- tryCatch(as.Date(prices$date), error = function(e) NULL)
  if (is.null(dates) || anyNA(dates) || anyDuplicated(dates)) {
    stop("prices$date must contain valid, unique dates.", call. = FALSE)
  }
  if (!is.numeric(prices$close) || any(!is.finite(prices$close)) ||
      any(prices$close <= 0)) {
    stop("prices$close must contain finite, positive numeric prices.", call. = FALSE)
  }
  if (nrow(prices) <= lookback) {
    stop("More than lookback price observations are required.", call. = FALSE)
  }
  ordering <- order(dates)
  dates <- dates[ordering]
  close <- prices$close[ordering]
  targets <- seq.int(lookback + 1L, length(close))
  x <- vapply(seq_len(lookback), function(j) close[targets - lookback + j - 1L],
              numeric(length(targets)))
  # vapply simplifies a single sample to a vector; retain the matrix contract.
  x <- matrix(x, nrow = length(targets), ncol = lookback)
  colnames(x) <- paste0("lag_", seq.int(lookback, 1L))
  list(x = x, y = close[targets], dates = dates[targets],
       feature_end_dates = dates[targets - 1L])
}

split_lagged_data <- function(dataset, train_fraction = 0.8) {
  if (length(train_fraction) != 1L || !is.numeric(train_fraction) ||
      !is.finite(train_fraction) || train_fraction <= 0 || train_fraction >= 1) {
    stop("train_fraction must be strictly between 0 and 1.", call. = FALSE)
  }
  required <- c("x", "y", "dates", "feature_end_dates")
  if (!is.list(dataset) || !all(required %in% names(dataset)) ||
      !is.matrix(dataset$x) || !is.numeric(dataset$x)) {
    stop("dataset must be produced by make_lagged_data().", call. = FALSE)
  }
  n <- nrow(dataset$x)
  if (any(lengths(dataset[required[-1L]]) != n) ||
      any(!is.finite(dataset$x)) || any(!is.finite(dataset$y)) ||
      !inherits(dataset$dates, "Date") || !inherits(dataset$feature_end_dates, "Date") ||
      anyNA(dataset$dates) || anyNA(dataset$feature_end_dates) ||
      is.unsorted(dataset$dates, strictly = TRUE) ||
      any(dataset$feature_end_dates >= dataset$dates)) {
    stop("dataset has invalid values, dates, or inconsistent row counts.", call. = FALSE)
  }
  train_n <- floor(n * train_fraction)
  if (train_n < 1L || train_n >= n) {
    stop("The requested split must leave at least one train and test row.", call. = FALSE)
  }
  subset_rows <- function(rows) {
    list(x = dataset$x[rows, , drop = FALSE], y = dataset$y[rows],
         dates = dataset$dates[rows], feature_end_dates = dataset$feature_end_dates[rows])
  }
  list(train = subset_rows(seq_len(train_n)),
       test = subset_rows(seq.int(train_n + 1L, n)))
}

train_forecast_models <- function(stocks, config, output_dir) {
  required_config <- c("screened_symbols", "lookback", "train_fraction", "seed",
                       "rf_trees", "xgb_rounds")
  if (!is.list(config) || !all(required_config %in% names(config))) {
    stop("config must define: ", paste(required_config, collapse = ", "), ".", call. = FALSE)
  }
  symbols <- as.character(config$screened_symbols)
  if (!length(symbols) || anyNA(symbols) || any(!nzchar(symbols)) || anyDuplicated(symbols)) {
    stop("config$screened_symbols must contain unique stock symbols.", call. = FALSE)
  }
  if (!is.list(stocks) || is.null(names(stocks)) || anyDuplicated(names(stocks)) ||
      !all(symbols %in% names(stocks))) {
    stop("stocks must be a named list containing every screened symbol.", call. = FALSE)
  }
  seed <- .model_integer(config$seed, "seed", minimum = 0L)
  trees <- .model_integer(config$rf_trees, "rf_trees")
  rounds <- .model_integer(config$xgb_rounds, "xgb_rounds")
  for (package in c("randomForest", "xgboost")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Install the required R package before training: ", package, call. = FALSE)
    }
  }
  if (length(output_dir) != 1L || is.na(output_dir) || !nzchar(output_dir)) {
    stop("output_dir must be a nonempty path.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir)) stop("Could not create output_dir.", call. = FALSE)
  metrics <- predictions <- vector("list", length(symbols) * 2L)
  row <- 0L
  for (symbol in symbols) {
    message("Training RF/XGB: ", symbol)
    split <- split_lagged_data(make_lagged_data(stocks[[symbol]], config$lookback),
                              config$train_fraction)
    if (nrow(split$train$x) < 2L) {
      stop("At least two training rows are required for ", symbol, ".", call. = FALSE)
    }
    set.seed(seed)
    forest <- randomForest::randomForest(x = split$train$x, y = split$train$y,
                                          ntree = trees)
    train_matrix <- xgboost::xgb.DMatrix(split$train$x, label = split$train$y)
    boosted <- xgboost::xgb.train(
      params = list(objective = "reg:squarederror", seed = seed, nthread = 1L,
                    verbosity = 0L),
      data = train_matrix, nrounds = rounds, verbose = 0L
    )
    forecasts <- list(RF = as.numeric(stats::predict(forest, split$test$x)),
                      XGB = as.numeric(stats::predict(boosted,
                        xgboost::xgb.DMatrix(split$test$x))))
    for (model in names(forecasts)) {
      predicted <- forecasts[[model]]
      if (length(predicted) != length(split$test$y) || any(!is.finite(predicted)) ||
          predicted[1L] == 0) {
        stop("Invalid predictions for ", symbol, " / ", model, ".", call. = FALSE)
      }
      row <- row + 1L
      errors <- predicted - split$test$y
      metrics[[row]] <- data.frame(
        symbol = symbol, model = model, rmse = sqrt(mean(errors^2)),
        mae = mean(abs(errors)),
        # A predicted price-path change, not a realized trading-strategy return.
        predicted_period_return = tail(predicted, 1L) / predicted[1L] - 1,
        test_start = split$test$dates[1L], test_end = tail(split$test$dates, 1L),
        train_n = nrow(split$train$x), test_n = nrow(split$test$x)
      )
      predictions[[row]] <- data.frame(
        date = split$test$dates, symbol = symbol, model = model,
        actual = split$test$y, predicted = predicted
      )
    }
  }
  result <- list(metrics = do.call(rbind, metrics), predictions = do.call(rbind, predictions))
  utils::write.csv(result$metrics, file.path(output_dir, "forecast_metrics.csv"), row.names = FALSE)
  utils::write.csv(result$predictions, file.path(output_dir, "forecast_predictions.csv"), row.names = FALSE)
  result
}

# Load both halves together and reject stale results from different data/windows.
read_forecast_results <- function(metrics_path, predictions_path, stocks, config,
                                  allowed_models = c("RF", "XGB", "LSTM")) {
  present <- file.exists(c(metrics_path, predictions_path))
  if (!any(present)) return(NULL)
  if (!all(present)) stop("Incomplete model outputs; regenerate metrics and predictions together.")
  metrics <- utils::read.csv(metrics_path, colClasses = c(symbol = "character"))
  predictions <- utils::read.csv(predictions_path, colClasses = c(symbol = "character"))
  metric_columns <- c("symbol", "model", "rmse", "mae", "predicted_period_return",
                      "test_start", "test_end", "train_n", "test_n")
  prediction_columns <- c("date", "symbol", "model", "actual", "predicted")
  if (!all(metric_columns %in% names(metrics)) ||
      !all(prediction_columns %in% names(predictions)) || !nrow(metrics)) {
    stop("Invalid model CSV schema: ", metrics_path)
  }
  metrics <- metrics[, metric_columns]
  predictions <- predictions[, prediction_columns]
  predictions$date <- as.Date(predictions$date)
  numeric_columns <- c("rmse", "mae", "predicted_period_return", "train_n", "test_n")
  if (anyNA(metrics) || anyNA(predictions) ||
      any(!is.finite(as.matrix(metrics[, numeric_columns]))) ||
      !is.numeric(predictions$actual) || !is.numeric(predictions$predicted) ||
      any(!is.finite(predictions$actual)) || any(!is.finite(predictions$predicted)) ||
      any(!metrics$model %in% allowed_models) ||
      any(!metrics$symbol %in% names(stocks)) ||
      anyDuplicated(metrics[, c("symbol", "model")]) ||
      anyDuplicated(predictions[, c("date", "symbol", "model")])) {
    stop("Invalid or duplicated model output values: ", metrics_path)
  }
  expected_count <- 0L
  for (i in seq_len(nrow(metrics))) {
    metric <- metrics[i, ]
    split <- split_lagged_data(make_lagged_data(stocks[[metric$symbol]], config$lookback),
                              config$train_fraction)
    rows <- predictions[predictions$symbol == metric$symbol & predictions$model == metric$model, ]
    rows <- rows[order(rows$date), ]
    if (nrow(rows) != length(split$test$y) ||
        !identical(rows$date, split$test$dates) ||
        max(abs(rows$actual - split$test$y)) > 1e-7 ||
        metric$train_n != nrow(split$train$x) || metric$test_n != nrow(split$test$x) ||
        metric$test_start != as.character(min(rows$date)) ||
        metric$test_end != as.character(max(rows$date)) || rows$predicted[1L] == 0) {
      stop("Model outputs do not match current data/windows for ", metric$symbol,
           "/", metric$model, "; rerun its trainer.")
    }
    errors <- rows$predicted - rows$actual
    recomputed <- c(sqrt(mean(errors^2)), mean(abs(errors)),
                    tail(rows$predicted, 1L) / rows$predicted[1L] - 1)
    if (max(abs(recomputed - unlist(metric[, numeric_columns[1:3]]))) > 1e-6) {
      stop("Model metrics disagree with predictions for ", metric$symbol, "/", metric$model)
    }
    expected_count <- expected_count + nrow(rows)
  }
  if (expected_count != nrow(predictions)) stop("Unmatched rows in prediction CSV.")
  list(metrics = metrics, predictions = predictions)
}
