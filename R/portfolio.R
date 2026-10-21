# Portfolio calculations use simple returns expressed as fractions. Expected
# returns, covariance matrices, and risk-free rates passed to optimizers are annual.

.portfolio_scalar <- function(value, label, lower = -Inf, strict = FALSE) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      (strict && value <= lower) || (!strict && value < lower)) {
    stop(label, " must be a finite number ", if (strict) "greater than " else "at least ",
         lower, ".", call. = FALSE)
  }
  value
}

.portfolio_matrix <- function(value, label, min_rows = 2L) {
  value <- as.matrix(value)
  if (!is.numeric(value) || length(dim(value)) != 2L ||
      nrow(value) < min_rows || ncol(value) < 1L || any(!is.finite(value))) {
    stop(label, " must be a finite numeric matrix with at least ", min_rows,
         " rows and one asset column.", call. = FALSE)
  }
  if (is.null(colnames(value))) colnames(value) <- paste0("asset_", seq_len(ncol(value)))
  assets <- colnames(value)
  if (anyNA(assets) || any(!nzchar(assets)) || anyDuplicated(assets)) {
    stop(label, " must have unique, nonempty asset column names.", call. = FALSE)
  }
  value
}

.portfolio_named_vector <- function(value, assets, label, require_names = FALSE) {
  if (!is.numeric(value) || length(value) != length(assets) || any(!is.finite(value))) {
    stop(label, " must contain one finite numeric value per asset.", call. = FALSE)
  }
  if (is.null(names(value))) {
    if (require_names) stop(label, " must be named by asset.", call. = FALSE)
    names(value) <- assets
  } else {
    if (anyNA(names(value)) || anyDuplicated(names(value)) ||
        !setequal(names(value), assets)) {
      stop(label, " names must match the asset columns exactly.", call. = FALSE)
    }
    value <- value[assets]
  }
  value
}

.portfolio_weights <- function(value, assets, label = "weights", require_names = FALSE) {
  value <- .portfolio_named_vector(value, assets, label, require_names)
  if (any(value < -1e-10) || abs(sum(value) - 1) > 1e-7) {
    stop(label, " must be nonnegative and sum to one.", call. = FALSE)
  }
  # Remove harmless optimizer rounding errors, without changing the allocation.
  value <- pmax(value, 0)
  value / sum(value)
}

.portfolio_covariance <- function(value, assets, label = "covariance", ridge = TRUE) {
  value <- as.matrix(value)
  n_assets <- length(assets)
  if (!is.numeric(value) || !identical(dim(value), c(n_assets, n_assets)) ||
      any(!is.finite(value))) {
    stop(label, " must be a finite square matrix with one row and column per asset.",
         call. = FALSE)
  }
  if (!is.null(rownames(value)) || !is.null(colnames(value))) {
    if (is.null(rownames(value)) || is.null(colnames(value)) ||
        anyDuplicated(rownames(value)) || anyDuplicated(colnames(value)) ||
        !setequal(rownames(value), assets) || !setequal(colnames(value), assets)) {
      stop(label, " row and column names must match the assets exactly.", call. = FALSE)
    }
    value <- value[assets, assets, drop = FALSE]
  }
  scale <- max(abs(value), 1e-12)
  if (max(abs(value - t(value))) > 1e-8 * scale) {
    stop(label, " must be symmetric.", call. = FALSE)
  }
  value <- (value + t(value)) / 2
  dimnames(value) <- list(assets, assets)
  eigenvalues <- eigen(value, symmetric = TRUE, only.values = TRUE)$values
  tolerance <- max(max(abs(eigenvalues)) * 1e-10, 1e-12)
  if (min(eigenvalues) < -100 * tolerance) {
    stop(label, " must be positive semidefinite.", call. = FALSE)
  }
  if (ridge && min(eigenvalues) < tolerance) {
    adjustment <- tolerance - min(eigenvalues)
    diag(value) <- diag(value) + adjustment
    warning(label, " is singular or nearly singular; added a diagonal ridge of ",
            format(adjustment, scientific = TRUE), " for stable optimization.", call. = FALSE)
  }
  value
}

.portfolio_annual_inputs <- function(returns, trading_days, expected_returns = NULL,
                                     covariance = NULL) {
  returns <- .portfolio_matrix(returns, "returns")
  trading_days <- .portfolio_scalar(trading_days, "trading_days", 0, strict = TRUE)
  assets <- colnames(returns)
  if (is.null(expected_returns)) expected_returns <- colMeans(returns) * trading_days
  expected_returns <- .portfolio_named_vector(expected_returns, assets, "expected_returns")
  if (is.null(covariance)) covariance <- stats::cov(returns) * trading_days
  covariance <- .portfolio_covariance(covariance, assets)
  list(returns = returns, assets = assets, expected_returns = expected_returns,
       covariance = covariance)
}

# Long-only mean-variance frontier. The grid follows the efficient branch from
# the global minimum-variance portfolio to the highest feasible expected return.
# Any expected_returns/covariance overrides must already be annualized.
fit_frontier <- function(returns, risk_free_rate = 0.01565, trading_days = 252L,
                         points = 150L, expected_returns = NULL, covariance = NULL) {
  risk_free_rate <- .portfolio_scalar(risk_free_rate, "risk_free_rate")
  points <- .portfolio_scalar(points, "points", 2)
  if (points != as.integer(points)) stop("points must be an integer.", call. = FALSE)
  input <- .portfolio_annual_inputs(returns, trading_days, expected_returns, covariance)
  assets <- input$assets
  mu <- input$expected_returns
  sigma <- input$covariance
  n_assets <- length(assets)
  if (n_assets > 1L && !requireNamespace("quadprog", quietly = TRUE)) {
    stop("fit_frontier requires the 'quadprog' package.", call. = FALSE)
  }

  solve_minimum <- function(indices = seq_len(n_assets)) {
    count <- length(indices)
    if (count == 1L) {
      solution <- 1
    } else {
      solution <- quadprog::solve.QP(
        Dmat = 2 * sigma[indices, indices, drop = FALSE], dvec = rep(0, count),
        Amat = cbind(rep(1, count), diag(count)), bvec = c(1, rep(0, count)), meq = 1L
      )$solution
    }
    weights <- stats::setNames(numeric(n_assets), assets)
    weights[indices] <- solution
    .portfolio_weights(weights, assets, "minimum-variance weights")
  }

  minimum <- tryCatch(solve_minimum(), error = function(error) {
    stop("Minimum-variance optimization failed: ", conditionMessage(error), call. = FALSE)
  })
  minimum_return <- sum(minimum * mu)
  span <- max(mu) - min(mu)
  mean_tolerance <- max(1, max(abs(mu))) * 1e-10
  targets <- if (span <= mean_tolerance || max(mu) - minimum_return <= mean_tolerance) {
    minimum_return
  } else {
    seq(minimum_return, max(mu), length.out = as.integer(points))
  }
  scaled_mu <- if (span > mean_tolerance) (mu - min(mu)) / span else rep(0, n_assets)
  solve_target <- function(target) {
    if (target < minimum_return - mean_tolerance || target > max(mu) + mean_tolerance) {
      stop("Requested return lies outside the efficient frontier's feasible range.")
    }
    if (abs(target - minimum_return) <= mean_tolerance) return(minimum)
    if (abs(target - max(mu)) <= mean_tolerance) {
      # At the boundary only assets attaining the maximum mean can be held.
      return(solve_minimum(which(abs(mu - max(mu)) <= mean_tolerance)))
    }
    weights <- quadprog::solve.QP(
      Dmat = 2 * sigma, dvec = rep(0, n_assets),
      Amat = cbind(rep(1, n_assets), scaled_mu, diag(n_assets)),
      bvec = c(1, (target - min(mu)) / span, rep(0, n_assets)), meq = 2L
    )$solution
    weights <- .portfolio_weights(weights, assets, "optimized weights")
    if (abs(sum(weights * mu) - target) > max(1e-7, span * 1e-6)) {
      stop("The solver did not attain the requested expected return.")
    }
    weights
  }
  portfolio_curve <- function(weights) {
    expected <- drop(weights %*% mu)
    volatility <- sqrt(pmax(rowSums((weights %*% sigma) * weights), 0))
    sharpe <- ifelse(volatility > 0, (expected - risk_free_rate) / volatility, NA_real_)
    data.frame(expected_return = expected, volatility = volatility, sharpe = sharpe)
  }
  best_sharpe_row <- function(curve) {
    if (all(is.na(curve$sharpe))) return(1L)
    which.max(replace(curve$sharpe, is.na(curve$sharpe), -Inf))
  }
  solutions <- vector("list", length(targets))
  failures <- character()
  for (index in seq_along(targets)) {
    target <- targets[index]
    solutions[index] <- list(tryCatch(solve_target(target), error = function(error) {
      failures <<- c(failures, paste0("target ", signif(target, 6), ": ", conditionMessage(error)))
      NULL
    }))
  }
  keep <- !vapply(solutions, is.null, logical(1))
  if (!any(keep)) {
    stop("All frontier optimizations failed: ", paste(unique(failures), collapse = "; "),
         call. = FALSE)
  }
  if (length(failures)) {
    warning(length(failures), " frontier target(s) failed; valid portfolios were retained. ",
            paste(utils::head(unique(failures), 3L), collapse = "; "), call. = FALSE)
  }
  weights <- do.call(rbind, solutions[keep])
  colnames(weights) <- assets
  rownames(weights) <- NULL
  curve <- portfolio_curve(weights)
  best <- best_sharpe_row(curve)
  # The plotting grid locates the optimum's neighborhood; refine the target
  # return continuously so the tangency/CML do not depend on plotting resolution.
  candidate_targets <- c(minimum_return, max(mu))
  if (nrow(curve) > 1L && span > mean_tolerance) {
    interval <- curve$expected_return[c(max(1L, best - 1L), min(nrow(curve), best + 1L))]
    if (diff(interval) > mean_tolerance) {
      refined <- tryCatch(stats::optimize(function(target) {
        weight <- solve_target(target)
        volatility <- sqrt(as.numeric(crossprod(weight, sigma %*% weight)))
        -(sum(weight * mu) - risk_free_rate) / volatility
      }, interval = interval, tol = max(1e-10, span * 1e-8)), error = function(error) {
        warning("Tangency refinement failed; retaining the best grid portfolio: ",
                conditionMessage(error), call. = FALSE)
        NULL
      })
      if (!is.null(refined)) candidate_targets <- c(candidate_targets, refined$minimum)
    }
  }
  # Always compare the exact global frontier endpoints as well as the refined
  # interior candidate. Keep the winning allocation in the returned plot data.
  for (target in unique(candidate_targets)) {
    if (any(abs(curve$expected_return - target) <= mean_tolerance)) next
    candidate <- tryCatch(solve_target(target), error = function(error) {
      warning("Additional tangency candidate failed at return ", signif(target, 6),
              ": ", conditionMessage(error), call. = FALSE)
      NULL
    })
    if (is.null(candidate)) next
    weights <- rbind(weights, candidate)
    curve <- portfolio_curve(weights)
  }
  ordering <- order(curve$expected_return)
  curve <- curve[ordering, , drop = FALSE]
  weights <- weights[ordering, , drop = FALSE]
  rownames(curve) <- rownames(weights) <- NULL
  best <- best_sharpe_row(curve)
  tangency_method <- "Maximum Sharpe on the efficient branch; continuous local refinement and endpoint comparison."
  if (max(mu) <= risk_free_rate) {
    tangency_method <- paste(tangency_method,
                            "All expected excess returns are nonpositive; this is not guaranteed to maximize Sharpe over inefficient portfolios.")
    warning("All expected returns are at or below the risk-free rate; returning the largest ",
            "Sharpe on the efficient branch, which need not be the global largest Sharpe ",
            "among all fully invested portfolios.", call. = FALSE)
  }
  list(curve = curve, weights = weights,
       tangency = stats::setNames(as.numeric(weights[best, ]), assets),
       minimum_variance = minimum, expected_returns = mu, covariance = sigma,
       tangency_method = tangency_method)
}

# Absolute annual investor views are combined with a fixed equilibrium prior.
# The posterior covariance includes uncertainty in the posterior mean.
black_litterman <- function(returns, prior_weights, views, tau = 0.05,
                            risk_aversion = 2.5, trading_days = 252L, omega = NULL) {
  tau <- .portfolio_scalar(tau, "tau", 0, strict = TRUE)
  risk_aversion <- .portfolio_scalar(risk_aversion, "risk_aversion", 0, strict = TRUE)
  input <- .portfolio_annual_inputs(returns, trading_days)
  assets <- input$assets
  sigma <- input$covariance
  prior_weights <- .portfolio_weights(prior_weights, assets, "prior_weights", require_names = TRUE)
  if (!is.numeric(views) || !length(views) || any(!is.finite(views)) ||
      is.null(names(views)) || anyNA(names(views)) || anyDuplicated(names(views)) ||
      any(!names(views) %in% assets)) {
    stop("views must be a finite named vector of absolute annual returns for known assets.",
         call. = FALSE)
  }
  view_assets <- names(views)
  picking <- diag(length(assets))[match(view_assets, assets), , drop = FALSE]
  dimnames(picking) <- list(view_assets, assets)
  tau_sigma <- tau * sigma
  view_prior_covariance <- picking %*% tau_sigma %*% t(picking)
  if (is.null(omega)) {
    omega <- diag(diag(view_prior_covariance), nrow = length(views))
    dimnames(omega) <- list(view_assets, view_assets)
  }
  omega <- .portfolio_covariance(omega, view_assets, "omega", ridge = FALSE)
  prior <- stats::setNames(drop(risk_aversion * sigma %*% prior_weights), assets)
  middle <- view_prior_covariance + omega
  cross_covariance <- tau_sigma %*% t(picking)
  adjustment <- tryCatch(
    solve(middle, views - drop(picking %*% prior)),
    error = function(error) stop("BL view update failed: ", conditionMessage(error), call. = FALSE)
  )
  posterior_returns <- stats::setNames(drop(prior + cross_covariance %*% adjustment), assets)
  posterior_mean_covariance <- tau_sigma - cross_covariance %*%
    solve(middle, picking %*% tau_sigma)
  posterior_covariance <- sigma + posterior_mean_covariance
  posterior_covariance <- (posterior_covariance + t(posterior_covariance)) / 2
  dimnames(posterior_covariance) <- list(assets, assets)
  list(expected_returns = posterior_returns, covariance = posterior_covariance,
       prior_returns = prior, views = views, omega = omega)
}

# Initial weights buy fixed shares at the first observed prices. This is a
# buy-and-hold wealth series; weights drift naturally as prices change.
portfolio_wealth <- function(prices, weights) {
  prices <- .portfolio_matrix(prices, "prices", min_rows = 1L)
  if (any(prices <= 0)) stop("prices must be strictly positive.", call. = FALSE)
  weights <- .portfolio_weights(weights, colnames(prices))
  wealth <- drop(sweep(prices, 2L, prices[1L, ], "/") %*% weights)
  names(wealth) <- rownames(prices)
  wealth
}

# Period return is realized over the observed interval; annualized return is
# geometric. Volatility and Sharpe use simple daily returns and an annual rf.
# Maximum drawdown is reported as a nonpositive fraction.
performance_summary <- function(wealth, risk_free_rate = 0.01565, trading_days = 252L) {
  wealth <- .portfolio_matrix(wealth, "wealth")
  risk_free_rate <- .portfolio_scalar(risk_free_rate, "risk_free_rate")
  trading_days <- .portfolio_scalar(trading_days, "trading_days", 0, strict = TRUE)
  if (any(wealth <= 0)) stop("wealth must be strictly positive.", call. = FALSE)
  daily_returns <- wealth[-1L, , drop = FALSE] /
    wealth[-nrow(wealth), , drop = FALSE] - 1
  count <- nrow(daily_returns)
  period_growth <- wealth[nrow(wealth), ] / wealth[1L, ]
  volatility <- vapply(seq_len(ncol(wealth)), function(index) {
    if (count < 2L) NA_real_ else stats::sd(daily_returns[, index]) * sqrt(trading_days)
  }, numeric(1))
  annual_arithmetic <- colMeans(daily_returns) * trading_days
  sharpe <- ifelse(!is.na(volatility) & volatility > .Machine$double.eps,
                   (annual_arithmetic - risk_free_rate) / volatility, NA_real_)
  drawdown <- vapply(seq_len(ncol(wealth)), function(index) {
    min(wealth[, index] / cummax(wealth[, index]) - 1)
  }, numeric(1))
  data.frame(name = colnames(wealth), period_return = unname(period_growth - 1),
             annualized_return = unname(period_growth^(trading_days / count) - 1),
             volatility = volatility, sharpe = unname(sharpe), max_drawdown = drawdown,
             row.names = NULL, check.names = FALSE)
}
