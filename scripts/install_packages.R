# Explicit setup only. Normal analysis never installs packages or accesses APIs.
args <- commandArgs(trailingOnly = TRUE)
unknown <- setdiff(args, c("--models", "--diagnostics", "--all"))
if (length(unknown)) stop("Unknown option: ", paste(unknown, collapse = ", "))
packages <- c("readxl", "quadprog", "igraph")
if (any(c("--models", "--all") %in% args)) packages <- c(packages, "randomForest", "xgboost")
if (any(c("--diagnostics", "--all") %in% args)) packages <- c(packages, "tseries")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
still_missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(still_missing)) stop("Installation incomplete: ", paste(still_missing, collapse = ", "))
message("Ready: ", paste(packages, collapse = ", "))
