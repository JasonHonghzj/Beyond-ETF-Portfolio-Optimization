# Run with Rscript --vanilla run.R, or source this file and call run_project().
.runner_args <- commandArgs(trailingOnly = FALSE)
.runner_file <- grep("^--file=", .runner_args, value = TRUE)
.source_file <- NULL
for (.frame in rev(sys.frames())) {
  if (!is.null(.frame$ofile)) { .source_file <- .frame$ofile; break }
}
if (!is.null(.source_file)) {
  .project_root <- dirname(normalizePath(.source_file, winslash = "/"))
} else if (length(.runner_file)) {
  .project_root <- dirname(normalizePath(sub("^--file=", "", .runner_file[1L]), winslash = "/"))
} else {
  .project_root <- getwd()
}

run_project <- function(root = .project_root, train = FALSE, all_pairs = FALSE,
                        figure_format = "png", output_dir = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  for (module in c("config", "data", "models", "portfolio", "plots")) {
    source(file.path(root, "R", paste0(module, ".R")), local = TRUE, encoding = "UTF-8")
  }
  require_packages(c("readxl", "quadprog", "igraph"))
  if (!figure_format %in% c("png", "pdf")) stop("figure_format must be png or pdf.")
  config <- project_config(root)
  config$figure_format <- figure_format
  if (is.null(output_dir)) output_dir <- file.path(root, "outputs")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)
  tables_dir <- file.path(output_dir, "tables")
  figures_dir <- file.path(output_dir, "figures")
  models_dir <- file.path(output_dir, "models")
  for (path in c(tables_dir, figures_dir, models_dir)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  write_table <- function(data, name) {
    if (!is.null(data)) utils::write.csv(data, file.path(tables_dir, name), row.names = FALSE)
  }

  message("Loading the 30 stocks and 10 ETFs once, in chronological order.")
  stocks <- load_prices(root, config$stock_dir, config$stock_symbols, config$data_start, config$data_end)
  etfs <- load_prices(root, config$etf_dir, config$etf_symbols, config$data_start, config$data_end)
  stock_prices <- align_prices(stocks)
  stock_returns <- price_returns(stock_prices, "log")
  correlation <- stats::cor(stock_returns)
  selection <- select_low_correlation(correlation, config$correlation_threshold)
  evaluation_prices <- align_prices(c(stocks[config$final_symbols], etfs),
                                    config$evaluation_start, config$evaluation_end)
  selected_prices <- evaluation_prices[, c("date", config$final_symbols), drop = FALSE]
  returns <- price_returns(selected_prices, "simple")
  weights <- sweep(config$presentation_weights, 2L, colSums(config$presentation_weights), "/")
  wealth <- data.frame(date = evaluation_prices$date)
  for (model in colnames(weights)) {
    wealth[[model]] <- portfolio_wealth(as.matrix(selected_prices[, -1L]), weights[, model])
  }
  for (symbol in config$etf_symbols) {
    wealth[[symbol]] <- evaluation_prices[[symbol]] / evaluation_prices[[symbol]][1L]
  }
  performance <- performance_summary(as.matrix(wealth[, -1L]), config$risk_free_rate,
                                     config$trading_days)

  message("Recomputing MV/BL fits on the evaluation window (in-sample diagnostics).")
  mv <- fit_frontier(returns, config$risk_free_rate, config$trading_days, config$frontier_points)
  bl <- black_litterman(returns, config$bl_prior_weights, config$bl_views,
                       config$bl_tau, config$bl_risk_aversion, config$trading_days,
                       omega = config$bl_omega)
  bl_fit <- fit_frontier(returns, config$risk_free_rate, config$trading_days,
                        config$frontier_points, bl$expected_returns, bl$covariance)
  recalculated_weights <- cbind(MV = mv$tangency, BL = bl_fit$tangency,
                                `1/N` = setNames(rep(1 / 6, 6), config$final_symbols))
  recalculated_wealth <- data.frame(date = evaluation_prices$date)
  for (model in colnames(recalculated_weights)) {
    recalculated_wealth[[model]] <- portfolio_wealth(as.matrix(selected_prices[, -1L]),
                                                   recalculated_weights[, model])
  }
  analysis <- list(stock_prices = stock_prices, stock_returns = stock_returns,
                   correlation = correlation, selection = selection,
                   evaluation_prices = evaluation_prices, wealth = wealth,
                   performance = performance, weights = weights,
                   mv_frontier = mv, bl_frontier = bl_fit, bl = bl)
  write_table(descriptive_statistics(stocks), "stock_descriptive_statistics.csv")
  write_table(descriptive_statistics(etfs), "etf_descriptive_statistics.csv")
  write_table(stationarity_tests(c(stocks, etfs)), "adf_tests.csv")
  write_table(data.frame(symbol = rownames(correlation), correlation, check.names = FALSE),
              "stock_return_correlations.csv")
  symbols <- sort(unique(c(config$screened_symbols, selection)))
  write_table(data.frame(symbol = symbols,
                         in_presentation = symbols %in% config$screened_symbols,
                         in_recomputed_clique = symbols %in% selection),
              "stock_selection_comparison.csv")
  write_table(data.frame(symbol = rownames(weights), weights, check.names = FALSE),
              "presentation_weights_normalized.csv")
  write_table(performance, "presentation_price_performance.csv")
  write_table(wealth, "presentation_buy_and_hold_wealth.csv")
  write_table(data.frame(symbol = rownames(recalculated_weights), recalculated_weights,
                         check.names = FALSE), "recomputed_in_sample_weights.csv")
  write_table(recalculated_wealth, "recomputed_in_sample_wealth.csv")
  write_table(performance_summary(as.matrix(recalculated_wealth[, -1L]),
                                  config$risk_free_rate, config$trading_days),
              "recomputed_in_sample_performance.csv")
  write_table(mv$curve, "mv_frontier.csv")
  write_table(bl_fit$curve, "bl_frontier.csv")
  write_table(data.frame(symbol = names(bl$prior_returns), prior = bl$prior_returns,
                         view = config$bl_views[names(bl$prior_returns)],
                         posterior = bl$expected_returns), "bl_annual_returns.csv")

  # Model retraining is explicit. Historical ML results are kept as evidence.
  historical_path <- file.path(root, config$historical_ml_file)
  if (file.exists(historical_path)) {
    historical <- as.data.frame(readxl::read_xlsx(historical_path))
    write_table(historical, "historical_ml_returns_percent.csv")
  }
  if (isTRUE(train)) {
    fitted <- train_forecast_models(stocks, config, models_dir)
  }
  # Reload validated RF/XGB as well as Python LSTM outputs on every run, so a
  # subsequent LSTM run cannot erase existing RF/XGB rows in the combined table.
  for (prefix in c("forecast", "lstm")) {
    saved <- read_forecast_results(file.path(models_dir, paste0(prefix, "_metrics.csv")),
                                   file.path(models_dir, paste0(prefix, "_predictions.csv")),
                                   stocks, config,
                                   if (prefix == "forecast") c("RF", "XGB") else "LSTM")
    if (!is.null(saved)) {
      analysis$forecast_metrics <- rbind(analysis$forecast_metrics, saved$metrics)
      analysis$forecast_predictions <- rbind(analysis$forecast_predictions, saved$predictions)
    }
  }
  if (!is.null(analysis$forecast_metrics)) {
    write_table(analysis$forecast_metrics, "combined_forecast_metrics.csv")
  } else {
    stale_combined <- file.path(tables_dir, "combined_forecast_metrics.csv")
    if (file.exists(stale_combined)) unlink(stale_combined)
  }
  message("Rendering the presentation figures from shared results.")
  figures <- render_presentation_figures(stocks, etfs, analysis, config, figures_dir, all_pairs)
  saveRDS(list(config = config, analysis = analysis), file.path(output_dir, "analysis.rds"))
  notes <- c(
    "Historical reconstruction and recomputed diagnostics; not an out-of-sample backtest.",
    paste("Evaluation:", min(wealth$date), "to", max(wealth$date)),
    paste("Annualization:", config$trading_days, "trading days; annual risk-free rate:", config$risk_free_rate),
    "Prices: local close, without dividend reinvestment, costs, taxes or corporate-action adjustment.",
    "Presentation portfolios: slide 45 rounded weights normalized to sum to one; fixed initial shares.",
    "The slide 45 return/volatility/Sharpe numbers are not hardcoded into recalculated results.",
    "Recomputed frontier portfolios use the same 2023 window for fitting and evaluation (in-sample).",
    "BL recomputation: sample covariance, equal-weight fixed prior, configured annual views/Omega.",
    "Original BL used Yahoo/LedoitWolf/current market caps/L2 regularization; exact reproduction is not claimed.",
    "Stock selection: recomputed log-return clique is diagnostic; original 22 and final 6 retained as historical selections.",
    "ML price-path changes are one-step prediction summaries using observed prior closes, not investable period-start forecasts.",
    "LSTM is trained separately: python scripts/train_lstm.py; rerun run.R to include its CSVs.",
    "Slide 39 pair 3711/2311 cannot be regenerated: 2311 is absent; no silent substitution.",
    paste("ADF available:", requireNamespace("tseries", quietly = TRUE)),
    "Recurrence figures: explicitly defined scalar z-score cross-recurrence, embedding=1, radius in config.",
    paste("RF/XGB retrained this run:", isTRUE(train)),
    paste("Figure files:", length(figures)),
    "", capture.output(utils::sessionInfo())
  )
  writeLines(notes, file.path(output_dir, "RUN_NOTES.txt"), useBytes = TRUE)
  message("Finished. Results: ", output_dir)
  invisible(list(config = config, analysis = analysis, figures = figures, output_dir = output_dir))
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if ("--help" %in% args) {
    cat("Rscript --vanilla run.R [--train] [--all-pairs] [--figure-format png|pdf] [--output-dir PATH]\n",
        "Default: historical reconstruction and recomputed in-sample diagnostics, without ML retraining.\n")
    return(invisible(NULL))
  }
  options <- list(train = FALSE, all_pairs = FALSE, figure_format = "png", output_dir = NULL)
  i <- 1L
  while (i <= length(args)) {
    option <- args[i]
    if (option == "--train") options$train <- TRUE else
    if (option == "--all-pairs") options$all_pairs <- TRUE else
    if (option %in% c("--figure-format", "--output-dir")) {
      i <- i + 1L
      if (i > length(args)) stop("Missing value for ", option)
      options[[if (option == "--figure-format") "figure_format" else "output_dir"]] <- args[i]
    } else stop("Unknown option: ", option, ". Use --help.")
    i <- i + 1L
  }
  do.call(run_project, options)
}

if (sys.nframe() == 0L) main()
