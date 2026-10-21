# Presentation figures share one renderer and the same analysis results.
# All rates accepted here are decimals; conversion to percent is display-only.

save_figure <- function(filename, draw, width = 1600, height = 1000, res = 150) {
  stopifnot(is.function(draw))
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  if (tolower(tools::file_ext(filename)) == "pdf") {
    grDevices::pdf(filename, width = width / res, height = height / res,
                   family = "Helvetica", useDingbats = FALSE)
  } else {
    grDevices::png(filename, width = width, height = height, res = res)
  }
  device <- grDevices::dev.cur()
  completed <- FALSE
  on.exit({
    if (device %in% grDevices::dev.list()) grDevices::dev.off(device)
    if (!completed && file.exists(filename)) unlink(filename)
  }, add = TRUE)
  graphics::par(family = "sans", las = 1, col.axis = "#374151",
                col.lab = "#374151", col.main = "#111827", fg = "#374151")
  draw()
  completed <- TRUE
  invisible(normalizePath(filename, winslash = "/", mustWork = TRUE))
}

figure_palette <- function(n) {
  grDevices::hcl.colors(n, palette = "Dark 3")
}

percent_axis <- function(side = 2, digits = 0) {
  at <- graphics::axTicks(side)
  graphics::axis(side, at = at,
                 labels = paste0(formatC(100 * at, format = "f", digits = digits), "%"),
                 las = 1)
}

plot_price_distributions <- function(series, title) {
  values <- lapply(series, function(x) x$close[is.finite(x$close)])
  graphics::par(mar = c(6, 5, 4, 1))
  graphics::boxplot(values, names = names(series), las = 2,
                    col = figure_palette(length(values)), border = "#475569",
                    outline = TRUE, main = title, ylab = "Closing price")
}

plot_price_trends <- function(series, title) {
  n <- length(series)
  columns <- if (n > 12L) 5L else 2L
  rows <- ceiling(n / columns)
  graphics::par(mfrow = c(rows, columns), mar = c(2.6, 3.1, 2.1, 0.6),
                oma = c(1, 1, 3, 0), mgp = c(1.6, 0.5, 0))
  colors <- figure_palette(n)
  for (i in seq_along(series)) {
    x <- series[[i]]
    order <- order(x$date)
    graphics::plot(x$date[order], x$close[order], type = "l", lwd = 1.2,
                   col = colors[i], main = names(series)[i], xlab = "", ylab = "Price",
                   cex.axis = 0.7, cex.lab = 0.8)
    graphics::grid(col = "#E5E7EB")
    graphics::lines(x$date[order], x$close[order], col = colors[i], lwd = 1.2)
  }
  graphics::mtext(title, outer = TRUE, side = 3, line = 0.5, font = 2, cex = 1.2)
}

plot_return_correlations <- function(correlation) {
  n <- nrow(correlation)
  colors <- grDevices::colorRampPalette(c("#2166AC", "#FFFFFF", "#B2182B"))(101)
  graphics::layout(matrix(c(1, 2), nrow = 1), widths = c(10, 1.1))
  graphics::par(mar = c(6, 6, 4, 1))
  graphics::image(seq_len(n), seq_len(n), t(correlation[n:1, , drop = FALSE]),
                  zlim = c(-1, 1), col = colors, axes = FALSE, xlab = "", ylab = "",
                  main = "Daily log-return correlations", useRaster = TRUE)
  graphics::axis(1, at = seq_len(n), labels = colnames(correlation), las = 2, cex.axis = 0.7)
  graphics::axis(2, at = seq_len(n), labels = rev(rownames(correlation)), las = 1, cex.axis = 0.7)
  graphics::box()
  graphics::par(mar = c(6, 0.5, 4, 3))
  graphics::image(1, seq(-1, 1, length.out = 101),
                  matrix(seq(-1, 1, length.out = 101), nrow = 1),
                  col = colors, axes = FALSE, xlab = "", ylab = "")
  graphics::axis(4, at = seq(-1, 1, by = 0.5), las = 1)
  graphics::box()
}

figure_return_series <- function(prices) {
  prices <- prices[order(prices$date), c("date", "close")]
  data.frame(date = prices$date[-1L], value = diff(log(prices$close)))
}

figure_pair_data <- function(series, pair) {
  if (length(pair) != 2L || !all(pair %in% names(series))) {
    warning("Skipping unavailable figure pair: ", paste(pair, collapse = "/"), call. = FALSE)
    return(NULL)
  }
  aligned <- merge(series[[pair[1L]]], series[[pair[2L]]], by = "date",
                   suffixes = c("_x", "_y"))
  aligned <- aligned[stats::complete.cases(aligned) &
                       is.finite(aligned[[2L]]) & is.finite(aligned[[3L]]), ]
  if (nrow(aligned) < 3L) {
    warning("Skipping figure pair with fewer than three shared observations: ",
            paste(pair, collapse = "/"), call. = FALSE)
    return(NULL)
  }
  aligned
}

cross_recurrence_matrix <- function(x, y, radius = 0.1) {
  if (!is.numeric(x) || !is.numeric(y) || !is.null(dim(x)) || !is.null(dim(y)) ||
      length(x) < 2L || length(y) < 2L) {
    stop("Cross-recurrence requires two numeric vectors with at least two values each.",
         call. = FALSE)
  }
  if (any(!is.finite(x)) || any(!is.finite(y))) {
    stop("Cross-recurrence requires finite values in both series.", call. = FALSE)
  }
  if (!is.numeric(radius) || length(radius) != 1L ||
      !is.finite(radius) || radius < 0) {
    stop("Cross-recurrence radius must be a finite nonnegative number.", call. = FALSE)
  }
  sx <- stats::sd(x)
  sy <- stats::sd(y)
  if (!is.finite(sx) || !is.finite(sy) || sx == 0 || sy == 0) {
    stop("Cross-recurrence cannot z-score a constant series or non-finite standard deviation.",
         call. = FALSE)
  }
  zx <- (x - mean(x)) / sx
  zy <- (y - mean(y)) / sy
  # Scalar recurrence only (embedding = 1, delay = 1), not full CRQA statistics.
  abs(outer(zx, zy, FUN = "-")) <= radius
}

plot_cross_recurrence <- function(recurrence, pair, radius) {
  graphics::par(mar = c(5, 5, 4, 2))
  graphics::image(seq_len(ncol(recurrence)), seq_len(nrow(recurrence)), t(recurrence),
                  col = c("white", "#111827"), zlim = c(0, 1),
                  xlab = paste(pair[2L], "observation index"),
                  ylab = paste(pair[1L], "observation index"),
                  main = paste("Cross-recurrence:", paste(pair, collapse = " / ")),
                  useRaster = TRUE)
  graphics::mtext(paste0("Cross-recurrence of z-scored closing prices; embedding=1; radius=", radius),
                  side = 3, line = 0.3, cex = 0.7)
}

plot_historical_annotation <- function(annotation, outer = FALSE) {
  if (!is.null(annotation)) {
    graphics::mtext(annotation, side = 3, line = 0.35, cex = 0.72,
                    col = "#475569", outer = outer)
  }
}

plot_portfolio_weights <- function(weights, annotation = NULL) {
  graphics::par(mfrow = c(1, 2), mar = c(2, 2, 4, 2),
                oma = c(0, 0, if (is.null(annotation)) 0 else 2, 0))
  colors <- figure_palette(nrow(weights))
  for (model in c("MV", "BL")) {
    w <- weights[, model]
    if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
      stop("Pie charts require finite, nonnegative portfolio weights.")
    }
    w <- w / sum(w)
    keep <- w > 1e-8
    labels <- paste0(rownames(weights)[keep], "\n", sprintf("%.1f%%", 100 * w[keep]))
    graphics::pie(w[keep], labels = labels, col = colors[keep], border = "white",
                  main = paste(model, "portfolio weights"), cex = 0.85)
  }
  plot_historical_annotation(annotation, outer = TRUE)
}

figure_portfolio_point <- function(weights, expected_returns, covariance) {
  assets <- names(expected_returns)
  if (is.null(names(weights))) names(weights) <- assets
  weights <- weights[assets]
  covariance <- covariance[assets, assets, drop = FALSE]
  c(volatility = sqrt(as.numeric(crossprod(weights, covariance %*% weights))),
    expected_return = sum(weights * expected_returns))
}

plot_fitted_frontier <- function(frontier, model, risk_free_rate) {
  curve <- frontier$curve
  curve <- curve[is.finite(curve$volatility) & is.finite(curve$expected_return), ]
  curve <- curve[order(curve$expected_return), ]
  if (!nrow(curve)) stop("No finite points in the ", model, " frontier.")
  tangency <- figure_portfolio_point(frontier$tangency,
                                     frontier$expected_returns, frontier$covariance)
  minimum <- figure_portfolio_point(frontier$minimum_variance,
                                    frontier$expected_returns, frontier$covariance)
  xmax <- max(curve$volatility, tangency["volatility"]) * 1.05
  ylim <- range(c(curve$expected_return, risk_free_rate,
                   tangency["expected_return"]), finite = TRUE)
  graphics::par(mar = c(5, 5, 5, 2))
  graphics::plot(curve$volatility, curve$expected_return, type = "l", lwd = 2.5,
                  col = "#2563EB", xlim = c(0, xmax), ylim = ylim, axes = FALSE,
                  xlab = "Annualized volatility", ylab = "Expected annual return",
                  main = paste(model, "efficient frontier"))
  percent_axis(1)
  percent_axis(2)
  graphics::box()
  graphics::grid(col = "#E5E7EB")
  graphics::lines(curve$volatility, curve$expected_return, lwd = 2.5, col = "#2563EB")
  # Show allocations from cash to the tangency portfolio, without extrapolating leverage.
  graphics::segments(0, risk_free_rate, tangency["volatility"],
                      tangency["expected_return"], lty = 2, col = "#B45309", lwd = 1.5)
  graphics::points(tangency["volatility"], tangency["expected_return"],
                   pch = 19, cex = 1.3, col = "#DC2626")
  graphics::points(minimum["volatility"], minimum["expected_return"],
                   pch = 17, cex = 1.3, col = "#047857")
  graphics::legend("topleft", legend = c("Efficient frontier", "Capital market line",
                                         "Tangency portfolio", "Minimum variance"),
                    col = c("#2563EB", "#B45309", "#DC2626", "#047857"),
                    lty = c(1, 2, NA, NA), pch = c(NA, NA, 19, 17),
                    lwd = c(2.5, 1.5, NA, NA), bty = "n", cex = 0.85)
  graphics::mtext("Recomputed in-sample fit", side = 3, line = 0.4, cex = 0.9)
}

figure_comparison_colors <- function(names) {
  colors <- rep("#94A3B8", length(names))
  highlight <- c(MV = "#0F766E", BL = "#2563EB", `1/N` = "#D97706")
  matched <- names %in% names(highlight)
  colors[matched] <- highlight[names[matched]]
  colors
}

plot_performance_bars <- function(performance, field, title, ylab, percentage = TRUE,
                                  annotation = NULL) {
  value <- performance[[field]]
  if (!length(value)) stop("Performance field ", field, " must contain values.")
  valid <- is.finite(value)
  plotted_value <- value
  plotted_value[!valid] <- 0
  limits <- range(c(0, value[valid]))
  span <- diff(limits)
  if (span == 0) span <- 1
  limits <- limits + c(-0.12, 0.18) * span
  graphics::par(mar = c(6, 5, 4, 1))
  centers <- graphics::barplot(plotted_value, names.arg = performance$name, las = 2,
                               col = figure_comparison_colors(performance$name),
                               border = NA, ylim = limits, yaxt = "n",
                               ylab = ylab, main = title)
  if (percentage) percent_axis(2) else graphics::axis(2, las = 1)
  graphics::abline(h = 0, col = "#64748B")
  labels <- rep("N/A", length(value))
  labels[valid] <- if (percentage) sprintf("%.1f%%", value[valid] * 100) else sprintf("%.2f", value[valid])
  graphics::text(centers, plotted_value, labels = labels,
                  pos = ifelse(plotted_value >= 0, 3, 1), cex = 0.7)
  plot_historical_annotation(annotation)
}

plot_cumulative_wealth <- function(wealth, annotation = NULL) {
  assets <- setdiff(names(wealth), "date")
  returns <- as.matrix(wealth[, assets, drop = FALSE]) - 1
  colors <- figure_palette(length(assets))
  portfolio <- assets %in% c("MV", "BL", "1/N")
  colors[portfolio] <- figure_comparison_colors(assets[portfolio])
  widths <- ifelse(portfolio, 2.3, 1.1)
  line_types <- ifelse(portfolio, 1, rep(c(2, 3), length.out = length(assets)))
  graphics::layout(matrix(c(1, 2), ncol = 1), heights = c(5, 1))
  graphics::par(mar = c(3, 5, 4, 2), xpd = FALSE)
  graphics::matplot(wealth$date, returns, type = "l", col = colors, lwd = widths,
                     lty = line_types, xaxt = "n", yaxt = "n", xlab = "", ylab = "Cumulative price return",
                     main = "Portfolio and ETF cumulative price returns")
  graphics::axis.Date(1, at = pretty(wealth$date), format = "%Y-%m")
  percent_axis(2)
  graphics::abline(h = 0, col = "#9CA3AF", lty = 3)
  plot_historical_annotation(annotation)
  graphics::par(mar = c(0, 1, 0, 1))
  graphics::plot.new()
  graphics::legend("center", legend = assets, col = colors,
                    lty = line_types, lwd = widths, ncol = min(5L, length(assets)),
                    bty = "n", xpd = FALSE, cex = 0.8)
}

plot_forecast_comparison <- function(predictions, symbol) {
  predictions$date <- as.Date(predictions$date, origin = "1970-01-01")
  predictions <- predictions[order(predictions$date), ]
  actual <- unique(predictions[, c("date", "actual")])
  actual <- actual[!is.na(actual$date) & is.finite(actual$actual), ]
  model_names <- unique(as.character(predictions$model))
  preferred <- c("RF", "XGB", "LSTM")
  model_names <- c(preferred[preferred %in% model_names],
                   sort(setdiff(model_names, preferred)))
  colors <- setNames(figure_palette(length(model_names)), model_names)
  fixed_colors <- c(RF = "#047857", XGB = "#2563EB", LSTM = "#D97706")
  matched <- model_names %in% names(fixed_colors)
  colors[matched] <- fixed_colors[model_names[matched]]
  values <- c(predictions$actual, predictions$predicted)
  limits <- range(values, finite = TRUE)
  padding <- max(diff(limits) * 0.10, max(abs(limits)) * 0.01, .01)
  graphics::par(mar = c(5, 5, 4, 2))
  graphics::plot(range(predictions$date, na.rm = TRUE), limits, type = "n",
                  ylim = limits + c(-padding, padding), xlab = "", ylab = "Closing price",
                  main = paste("Out-of-sample price forecasts:", symbol))
  graphics::grid(col = "#E5E7EB")
  graphics::lines(actual$date, actual$actual, col = "#111827", lwd = 2)
  for (model in model_names) {
    predicted <- predictions[!is.na(predictions$model) & predictions$model == model, ]
    graphics::lines(predicted$date, predicted$predicted, col = colors[model],
                    lwd = 1.4, lty = 2)
  }
  graphics::legend("topleft", legend = c("Actual", model_names),
                    col = c("#111827", colors), lty = c(1, rep(2, length(model_names))),
                    lwd = c(2, rep(1.4, length(model_names))), bty = "n", cex = 0.85)
}

render_presentation_figures <- function(stocks, etfs, analysis, config, output_dir,
                                        all_pairs = FALSE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  format <- if (is.null(config$figure_format)) "png" else tolower(config$figure_format)
  if (length(format) != 1L || !format %in% c("png", "pdf")) {
    stop("config$figure_format must be 'png' or 'pdf'.")
  }
  files <- character()
  write_figure <- function(name, draw, width = 1600, height = 1000) {
    file <- save_figure(file.path(output_dir, paste0(name, ".", format)), draw,
                        width = width, height = height)
    files <<- c(files, file)
    invisible(file)
  }
  write_figure("31_etf_price_boxplots", function() {
    plot_price_distributions(etfs, "ETF closing-price distributions")
  })
  write_figure("32_etf_price_trends", function() {
    plot_price_trends(etfs, "ETF closing-price history (individual scales)")
  }, height = 1600)
  write_figure("34_stock_price_boxplots", function() {
    plot_price_distributions(stocks, "Stock closing-price distributions")
  }, width = 2000)
  write_figure("35_stock_price_trends", function() {
    plot_price_trends(stocks, "Stock closing-price history (individual scales)")
  }, width = 2000, height = 1800)
  write_figure("41_stock_return_correlations", function() {
    plot_return_correlations(analysis$correlation)
  }, width = 1800, height = 1600)

  # Compute log returns once per source, then align return dates for each pair.
  sources <- c(stocks, etfs)
  sources <- sources[!duplicated(names(sources))]
  returns <- lapply(sources, figure_return_series)
  pairs <- config$ccf_pairs
  if (isTRUE(all_pairs) && length(stocks) >= 2L) {
    pairs <- c(pairs, utils::combn(names(stocks), 2, simplify = FALSE))
  }
  if (length(pairs)) {
    keys <- vapply(pairs, function(pair) paste(sort(pair), collapse = "_"), character(1))
    pairs <- pairs[!duplicated(keys)]
  }
  lag_max <- if (is.null(config$lag_max)) 20L else config$lag_max
  for (pair in pairs) {
    aligned <- figure_pair_data(returns, pair)
    if (is.null(aligned)) next
    if (stats::sd(aligned[[2L]]) == 0 || stats::sd(aligned[[3L]]) == 0) {
      warning("Skipping CCF for constant returns: ", paste(pair, collapse = "/"), call. = FALSE)
      next
    }
    correlation <- stats::ccf(aligned[[2L]], aligned[[3L]],
                               lag.max = min(lag_max, nrow(aligned) - 1L), plot = FALSE)
    write_figure(paste0("38_ccf_", paste(pair, collapse = "_")), function() {
      graphics::plot(correlation, main = paste("Daily log-return CCF:", paste(pair, collapse = " / ")),
                      xlab = "Lag (trading observations)", ylab = "Cross-correlation")
      graphics::mtext(paste(nrow(aligned), "shared return dates"), side = 3, line = 0.3, cex = 0.8)
    })
  }

  if (length(config$recurrence_pairs)) {
    prices <- lapply(sources, function(x) x[, c("date", "close")])
    radius <- if (is.null(config$recurrence_radius)) 0.1 else config$recurrence_radius
    for (pair in config$recurrence_pairs) {
      aligned <- figure_pair_data(prices, pair)
      if (is.null(aligned)) next
      recurrence <- cross_recurrence_matrix(aligned[[2L]], aligned[[3L]], radius)
      write_figure(paste0("39_recurrence_", paste(pair, collapse = "_")), function() {
        plot_cross_recurrence(recurrence, pair, radius)
      }, width = 1200, height = 1200)
    }
  }

  historical_note <- paste0("Normalized slide 45 weights; buy-and-hold; ",
                             format(min(analysis$wealth$date), "%Y-%m-%d"), " to ",
                             format(max(analysis$wealth$date), "%Y-%m-%d"))
  write_figure("46_portfolio_weights", function() {
    plot_portfolio_weights(analysis$weights, historical_note)
  })
  risk_free_rate <- if (is.null(config$risk_free_rate)) 0 else config$risk_free_rate
  write_figure("47_mv_frontier", function() {
    plot_fitted_frontier(analysis$mv_frontier, "MV", risk_free_rate)
  })
  write_figure("48_bl_frontier", function() {
    plot_fitted_frontier(analysis$bl_frontier, "BL", risk_free_rate)
  })
  write_figure("49_return_comparison", function() {
    plot_performance_bars(analysis$performance, "period_return", "Evaluation period price returns",
                          "Price return", annotation = historical_note)
  })
  write_figure("50_volatility_comparison", function() {
    plot_performance_bars(analysis$performance, "volatility", "Annualized volatility comparison",
                          "Annualized volatility", annotation = historical_note)
  })
  write_figure("51_sharpe_comparison", function() {
    plot_performance_bars(analysis$performance, "sharpe", "Annualized Sharpe ratio comparison",
                          "Sharpe ratio", percentage = FALSE, annotation = historical_note)
  })
  write_figure("52_cumulative_returns", function() {
    plot_cumulative_wealth(analysis$wealth, historical_note)
  }, height = 1100)

  predictions <- analysis$forecast_predictions
  if (!is.null(predictions)) {
    required <- c("date", "symbol", "model", "actual", "predicted")
    if (!is.data.frame(predictions) || !all(required %in% names(predictions))) {
      stop("analysis$forecast_predictions must contain: ", paste(required, collapse = ", "))
    }
    for (symbol in unique(as.character(predictions$symbol))) {
      values <- predictions[!is.na(predictions$symbol) & predictions$symbol == symbol, ]
      if (!nrow(values) || !any(is.finite(c(values$actual, values$predicted)))) {
        warning("Skipping forecast figure without finite values: ", symbol, call. = FALSE)
        next
      }
      filename <- paste0("models/forecast_", gsub("[^A-Za-z0-9_.-]", "_", symbol))
      write_figure(filename, function() plot_forecast_comparison(values, symbol))
    }
  }
  invisible(files)
}
