# Regression checks for the refactor's data alignment and financial calculations.
.test_file <- NULL
for (.frame in rev(sys.frames())) {
  if (!is.null(.frame$ofile)) { .test_file <- .frame$ofile; break }
}
if (is.null(.test_file)) {
  .test_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
}
root <- dirname(dirname(normalizePath(.test_file, winslash = "/", mustWork = TRUE)))
for (file in c(file.path(root, "run.R"), list.files(file.path(root, "R"), full.names = TRUE),
               file.path(root, "scripts", "install_packages.R"))) parse(file, encoding = "UTF-8")
for (module in c("config", "data", "models", "portfolio", "plots")) {
  source(file.path(root, "R", paste0(module, ".R")), encoding = "UTF-8")
}
require_packages(c("readxl", "quadprog", "igraph"))
checks <- 0L
check <- function(condition, label) {
  if (!isTRUE(condition)) stop("FAIL: ", label, call. = FALSE)
  checks <<- checks + 1L
}
near <- function(x, y, tolerance = 1e-8) isTRUE(all.equal(unname(x), unname(y), tolerance = tolerance))
fails <- function(expression) inherits(tryCatch({ force(expression); NULL }, error = identity), "error")

dates <- as.Date("2023-01-01") + 0:4
prices <- data.frame(date = dates, close = c(100, 110, 99, 120, 132))
check(identical(validate_prices(prices[5:1, ])$date, dates), "sort descending source dates")
check(fails(validate_prices(rbind(prices, prices[1L, ]))), "reject duplicate dates")
bad <- prices; bad$close[1L] <- 0
check(fails(validate_prices(bad)), "reject nonpositive prices")
series <- list(A = prices, B = data.frame(date = dates[-1L], close = c(20, 22, 24, 26)))
aligned <- align_prices(series)
check(identical(aligned$date, dates[-1L]) && near(aligned$A, c(110, 99, 120, 132)),
      "date intersection aligns values by date")
check(near(price_returns(data.frame(date = dates, A = prices$close))[, 1L],
           c(0.10, -0.10, 120 / 99 - 1, 0.10)), "simple daily returns")

window_prices <- data.frame(date = as.Date("2019-01-01") + 0:1194, close = 1:1195)
windows <- make_lagged_data(window_prices, 20L)
split <- split_lagged_data(windows, 0.8)
check(identical(dim(windows$x), c(1175L, 20L)), "20-day windows retain all targets")
check(near(windows$x[1L, ], 1:20) && windows$y[1L] == 21, "next-day target cannot appear in features")
check(nrow(split$train$x) == 940L && nrow(split$test$x) == 235L,
      "presentation chronological split 940/235")
check(max(split$train$dates) < min(split$test$dates) &&
        all(windows$feature_end_dates < windows$dates), "all forecast inputs precede their targets")

asset_prices <- cbind(A = c(10, 11, 12), B = c(1000, 800, 1100))
w <- c(A = 0.25, B = 0.75)
wealth <- portfolio_wealth(asset_prices, w)
check(near(wealth, c(1, 0.875, 1.125)), "capital allocations normalize initial prices")
check(near(wealth, portfolio_wealth(sweep(asset_prices, 2L, c(20, 0.01), "*"), w)),
      "wealth invariant to arbitrary per-share price scales")
check(near(wealth, portfolio_wealth(asset_prices, c(B = .75, A = .25))),
      "named weights follow asset names")
check(fails(portfolio_wealth(asset_prices, c(A = .5, B = .7))), "reject overweight capital allocations")
performance <- performance_summary(cbind(A = c(1, 1.2, 0.8, 1.1)), 0, 252)
check(near(performance$period_return, .1) && near(performance$max_drawdown, -1 / 3),
      "compound period return and running-peak drawdown")
check(near(performance$volatility, sd(c(.2, .8 / 1.2 - 1, 1.1 / .8 - 1)) * sqrt(252)),
      "annualized volatility uses daily portfolio wealth returns")

set.seed(1)
returns <- cbind(A = rnorm(100, .0004, .01), B = rnorm(100, .0006, .02))
mu <- c(A = .1, B = .2)
sigma <- diag(c(.04, .09)); dimnames(sigma) <- list(names(mu), names(mu))
fit <- fit_frontier(returns, .02, points = 3L, expected_returns = mu, covariance = sigma)
analytic <- solve(sigma, mu - .02); analytic <- analytic / sum(analytic)
check(near(fit$tangency, analytic, 1e-5), "refined tangency agrees with analytical two-asset solution")
check(all(fit$weights >= -1e-9) && all(abs(rowSums(fit$weights) - 1) < 1e-7),
      "all optimized frontier allocations are long-only and fully invested")
check(near(fit$curve$volatility,
           sqrt(rowSums((fit$weights %*% fit$covariance) * fit$weights))),
      "frontier curve risk uses its saved allocations")
equal <- fit_frontier(returns, .02, expected_returns = c(A = .1, B = .1), covariance = sigma)
check(nrow(equal$curve) == 1L && near(equal$tangency, c(.09, .04) / .13),
      "equal-mean frontier reduces to minimum variance")
one <- fit_frontier(returns[, "A", drop = FALSE], .02)
check(near(one$tangency, 1), "one-asset optimizer")
bl_weak <- black_litterman(returns, c(A = .5, B = .5), c(B = .3, A = .2),
                           omega = diag(1e12, 2))
check(near(bl_weak$expected_returns, bl_weak$prior_returns), "uncertain BL views approach fixed prior")
bl_strong <- black_litterman(returns, c(B = .5, A = .5), c(B = .3, A = .2),
                             omega = matrix(0, 2, 2))
check(near(bl_strong$expected_returns, c(A = .2, B = .3)), "certain views match named absolute returns")
check(fails(black_litterman(returns, c(A = .5, B = .5), c(C = .2))), "reject unknown BL view assets")

corr <- matrix(c(1, .1, .8, .1, 1, .2, .8, .2, 1), 3,
               dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
selected <- select_low_correlation(corr, .6)
check(identical(selected, c("A", "B")), "deterministic tie break for largest low-correlation clique")
config <- project_config(root)
actual <- load_prices(root, config$stock_dir, "2330")[[1L]]
actual_split <- split_lagged_data(make_lagged_data(actual))
check(nrow(actual) == 1195L && nrow(actual_split$train$x) == 940L &&
        nrow(actual_split$test$x) == 235L &&
        as.character(tail(actual_split$test$dates, 1L)) == "2023-11-30",
      "real workbook schema and forecast dates")

fixture_dir <- tempfile("saved-model-regression-")
dir.create(fixture_dir)
prediction_fixture <- data.frame(date = actual_split$test$dates, symbol = "2330",
                                  model = "RF", actual = actual_split$test$y,
                                  predicted = actual_split$test$y * 1.01)
error_fixture <- prediction_fixture$predicted - prediction_fixture$actual
metric_fixture <- data.frame(symbol = "2330", model = "RF",
  rmse = sqrt(mean(error_fixture^2)), mae = mean(abs(error_fixture)),
  predicted_period_return = tail(prediction_fixture$predicted, 1L) /
    prediction_fixture$predicted[1L] - 1,
  test_start = min(prediction_fixture$date), test_end = max(prediction_fixture$date),
  train_n = 940L, test_n = 235L)
metric_path <- file.path(fixture_dir, "metrics.csv")
prediction_path <- file.path(fixture_dir, "predictions.csv")
utils::write.csv(metric_fixture, metric_path, row.names = FALSE)
utils::write.csv(prediction_fixture, prediction_path, row.names = FALSE)
saved <- read_forecast_results(metric_path, prediction_path, list(`2330` = actual), config)
check(nrow(saved$metrics) == 1L && nrow(saved$predictions) == 235L,
      "saved model results reload with the same schema and dates")
changed_config <- config; changed_config$lookback <- 19L
check(fails(read_forecast_results(metric_path, prediction_path, list(`2330` = actual), changed_config)),
      "reject saved predictions for a different lookback")
prediction_fixture$actual[1L] <- prediction_fixture$actual[1L] + 1
utils::write.csv(prediction_fixture, prediction_path, row.names = FALSE)
check(fails(read_forecast_results(metric_path, prediction_path, list(`2330` = actual), config)),
      "reject saved predictions from different source prices")
check(fails(read_forecast_results(metric_path, paste0(prediction_path, ".missing"),
                                   list(`2330` = actual), config)),
      "reject incomplete saved model pairs")
recurrence <- cross_recurrence_matrix(c(1, 2, 3), c(3, 2, 1), 0)
check(identical(recurrence, matrix(c(FALSE, FALSE, TRUE, FALSE, TRUE, FALSE,
                                     TRUE, FALSE, FALSE), 3)), "scalar cross-recurrence definition")
check(fails(cross_recurrence_matrix(rep(1, 3), 1:3)), "reject undefined constant-series normalization")

if ("--models" %in% commandArgs(TRUE)) {
  config$screened_symbols <- "2330"
  config$rf_trees <- 5L; config$xgb_rounds <- 2L
  model_dir <- tempfile("model-regression-")
  result <- train_forecast_models(list(`2330` = actual), config, model_dir)
  check(nrow(result$metrics) == 2L && nrow(result$predictions) == 470L &&
          all(is.finite(result$metrics$rmse)), "RF/XGB real-workbook training smoke")
}
message("PASS: ", checks, " R regression checks.")
