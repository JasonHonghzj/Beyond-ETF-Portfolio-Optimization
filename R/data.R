require_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Missing R packages: ", paste(missing, collapse = ", "),
         ". Run Rscript scripts/install_packages.R.", call. = FALSE)
  }
  invisible(TRUE)
}

validate_prices <- function(data, label = "prices") {
  if (!is.data.frame(data) || !all(c("date", "close") %in% names(data))) {
    stop(label, " must have date and close columns.", call. = FALSE)
  }
  dates <- tryCatch(as.Date(data$date), error = function(e) rep(as.Date(NA), nrow(data)))
  if (nrow(data) < 3L || anyNA(dates) || anyDuplicated(dates)) {
    stop(label, ": need at least three unique, valid dates.", call. = FALSE)
  }
  if (!is.numeric(data$close) || any(!is.finite(data$close)) || any(data$close <= 0)) {
    stop(label, ": close prices must be finite positive numbers.", call. = FALSE)
  }
  result <- data.frame(date = dates, close = as.numeric(data$close))
  result <- result[order(result$date), , drop = FALSE]
  rownames(result) <- NULL
  result
}

load_prices <- function(root, folder, symbols, start = NULL, end = NULL) {
  require_packages("readxl")
  if (!length(symbols) || anyDuplicated(symbols)) stop("Symbols must be unique.")
  result <- lapply(symbols, function(symbol) {
    path <- file.path(root, folder, paste0(symbol, "_daily.xlsx"))
    if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
    data <- validate_prices(as.data.frame(readxl::read_xlsx(path)), symbol)
    if (!is.null(start)) data <- data[data$date >= as.Date(start), , drop = FALSE]
    if (!is.null(end)) data <- data[data$date <= as.Date(end), , drop = FALSE]
    validate_prices(data, symbol)
  })
  setNames(result, symbols)
}

align_prices <- function(series, start = NULL, end = NULL) {
  if (!length(series) || is.null(names(series)) || anyDuplicated(names(series))) {
    stop("Supply a named list of unique price series.")
  }
  common <- Reduce(intersect, lapply(series, function(x) as.character(x$date)))
  dates <- sort(as.Date(common))
  if (!is.null(start)) dates <- dates[dates >= as.Date(start)]
  if (!is.null(end)) dates <- dates[dates <= as.Date(end)]
  if (length(dates) < 3L) stop("Fewer than three common price dates.")
  result <- data.frame(date = dates)
  for (symbol in names(series)) {
    x <- validate_prices(series[[symbol]], symbol)
    result[[symbol]] <- x$close[match(dates, x$date)]
  }
  result
}

price_returns <- function(prices, type = c("simple", "log")) {
  type <- match.arg(type)
  x <- as.matrix(prices[, setdiff(names(prices), "date"), drop = FALSE])
  if (!is.numeric(x) || nrow(x) < 2L || any(!is.finite(x)) || any(x <= 0)) {
    stop("Returns require a positive numeric price matrix.")
  }
  result <- if (type == "log") diff(log(x)) else x[-1L, , drop = FALSE] /
    x[-nrow(x), , drop = FALSE] - 1
  rownames(result) <- as.character(prices$date[-1L])
  result
}

select_low_correlation <- function(correlation, threshold = 0.6) {
  require_packages("igraph")
  if (!is.matrix(correlation) || nrow(correlation) != ncol(correlation) ||
      any(!is.finite(correlation)) || threshold <= 0 || threshold > 1) {
    stop("Need a finite square correlation matrix and threshold in (0, 1].")
  }
  adjacency <- abs(correlation) < threshold
  diag(adjacency) <- FALSE
  graph <- igraph::graph_from_adjacency_matrix(adjacency, mode = "undirected", diag = FALSE)
  cliques <- igraph::largest_cliques(graph)
  # Stable tie-break makes tied largest cliques reproducible across igraph versions.
  candidates <- lapply(cliques, function(x) sort(igraph::as_ids(x)))
  keys <- vapply(candidates, paste, collapse = ",", FUN.VALUE = character(1))
  candidates[[order(keys)[1L]]]
}

descriptive_statistics <- function(series) {
  do.call(rbind, lapply(names(series), function(symbol) {
    x <- series[[symbol]]
    data.frame(symbol = symbol, n = nrow(x), start = min(x$date), end = max(x$date),
               min = min(x$close), median = median(x$close), mean = mean(x$close),
               max = max(x$close), sd = sd(x$close), row.names = NULL)
  }))
}

stationarity_tests <- function(series) {
  if (!requireNamespace("tseries", quietly = TRUE)) {
    warning("ADF tests skipped: optional package tseries is unavailable.", call. = FALSE)
    return(NULL)
  }
  do.call(rbind, lapply(names(series), function(symbol) {
    x <- series[[symbol]]$close
    # tseries warns when the p-value is outside its printed bounds; record the bound.
    raw <- suppressWarnings(tseries::adf.test(x))
    transformed <- suppressWarnings(tseries::adf.test(diff(log(x))))
    data.frame(symbol = symbol, price_p_value = raw$p.value,
               log_return_p_value = transformed$p.value,
               price_lag = unname(raw$parameter),
               log_return_lag = unname(transformed$parameter),
               p_value_note = "Approximate; values 0.01/0.99 may be reporting bounds")
  }))
}
