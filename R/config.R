# All project assumptions live here. Returns and rates use fractions, not percent.
project_config <- function(root = ".") {
  final <- c("3034", "2357", "2454", "2886", "3711", "2330")
  list(
    root = normalizePath(root, winslash = "/", mustWork = TRUE),
    stock_dir = file.path("data", "stocks"),
    etf_dir = file.path("data", "etfs"),
    historical_ml_file = file.path("data", "historical", "ml_returns.xlsx"),
    stock_symbols = c("2330", "2317", "2454", "2382", "2412", "2881",
                      "2308", "2882", "6505", "3711", "2303", "2891",
                      "2886", "1303", "1301", "1216", "2884", "6669",
                      "2002", "3045", "2885", "5880", "3034", "2892",
                      "2603", "2207", "3231", "2357", "2395", "1326"),
    etf_symbols = c("0050", "0056", "006208", "00713", "00712", "00692",
                    "00646", "00757", "00830", "00733"),
    screened_symbols = c("2317", "2330", "2395", "2357", "3231", "2207",
                         "2603", "3034", "3045", "2002", "6669", "1216",
                         "2303", "3711", "2308", "2412", "2382", "2454",
                         "2881", "2885", "2886", "6505"),
    final_symbols = final,
    data_start = as.Date("2019-01-02"), data_end = as.Date("2023-11-30"),
    evaluation_start = as.Date("2023-01-01"),
    evaluation_end = as.Date("2023-11-30"),
    trading_days = 252L, risk_free_rate = 0.01565,
    correlation_threshold = 0.6,
    lookback = 20L, train_fraction = 0.8, seed = 1L,
    rf_trees = 500L, xgb_rounds = 10L, frontier_points = 150L,
    # Slide 45 has rounded weights (MV sums to 1.001, BL to 0.993).
    # Normalize once before using them as initial capital allocations.
    presentation_weights = matrix(
      c(0.244, 0.184, 0.129, 0.440, 0.004, 0,
        0.180, 0.080, 0.190, 0.090, 0.170, 0.283,
        rep(1 / 6, 6)), nrow = 6,
      dimnames = list(final, c("MV", "BL", "1/N"))),
    # Absolute annual views and custom Omega from the final archived notebook.
    bl_views = setNames(c(0.765, 0.37, 0.30, 0.25, 0.24, 0.19), final),
    bl_omega = diag(c(0.015625, 0.0225, 0.015625, 0.005625, 0.0025, 0.0025)),
    bl_tau = 0.05, bl_risk_aversion = 2.5,
    # Offline prior assumption; not a claim about historical market weights.
    bl_prior_weights = setNames(rep(1 / 6, 6), final),
    lag_max = 20L,
    ccf_pairs = list(c("2330", "2317"), c("0050", "00646")),
    # Slide 39's 2311 is absent from the supplied data; do not substitute it.
    recurrence_pairs = list(c("2881", "2882"), c("2412", "6505")),
    recurrence_radius = 0.1,
    figure_format = "png"
  )
}
