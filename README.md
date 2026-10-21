# Beyond ETFs

English | [繁體中文](README_zh.md)

A **Spring 2024** final project for the Big Data Analytics course, studying stock forecasting and portfolio allocation against Taiwanese ETF benchmarks. R is the main analysis language; Python provides the PyTorch LSTM and bilingual report generation.

The research uses local market data ending **November 30, 2023**. Code organization, report reconstruction, and the complete native R/Python rerun were completed in **October 2026**; the latest full run is dated **October 21, 2026**. These dates describe maintenance and validation, not additional market data.

## Project overview

The project starts with 30 stocks and 10 ETFs. It examines descriptive statistics, stationarity, correlations, cross-correlations, and recurrence plots, then combines forecasting and asset allocation:

```text
30 stocks + 10 ETF benchmarks
  → correlation screening of the stocks (|r| < 0.6)
  → the presentation's 22-stock selection
  → RF / XGBoost / LSTM one-step price forecasts
  → the presentation's final six stocks
  → MV / Black–Litterman / equal-weight portfolios versus 10 ETFs
```

The final six stocks are **3034, 2357, 2454, 2886, 3711, and 2330**. Their historical selection and allocation weights are retained so the presentation can be inspected alongside independently recalculated results. New model training and portfolio refitting are reported separately.

| Start here | Contents |
|---|---|
| [Original presentation](docs/presentation.pdf) | The Spring 2024 project and original findings |
| [Chinese report](reports/report_zh/report_zh.pdf) / [English report](reports/report_en/report_en.pdf) | Course reports: objectives, methods, results, color figures, tables, and limitations |
| [Report guide](reports/README.md) | Editable report sources, author information, layout, fonts, and rebuild instructions |
| [Full execution summary](outputs/full_run/2026-10-21/RUN_SUMMARY.md) | Commands, logs, timings, and the complete 22-stock model comparison |
| [Model comparison CSV](outputs/full_run/2026-10-21/model_comparison.csv) | Per-stock RF, XGBoost, and LSTM test errors |

The reports use the OSDI 2024 template.

## Main results

The following results are recalculated from local closing prices for **January 3–November 30, 2023**, using the presentation's rounded weights normalized to sum to one and fixed initial share holdings.

| Historical portfolio | Period price return | Annualized volatility | Sharpe ratio |
|---|---:|---:|---:|
| Mean–variance (MV) | 40.4048% | 15.0980% | 2.584 |
| Black–Litterman (BL) | 38.7129% | 17.8242% | 2.134 |
| Equal weight (1/N) | 39.5722% | 16.5717% | 2.326 |

Source: [presentation_price_performance.csv](outputs/tables/presentation_price_performance.csv). Each portfolio's period price return exceeds **7 of the 10 ETF benchmarks**. This is not uniform outperformance: ETF 00757 has a higher return, while 00713 has lower volatility and a higher Sharpe ratio. The configuration uses 252 trading days for annualization and a 1.565% annual risk-free rate.

The final six-stock allocation below shows the **historical normalized initial capital weights** used for these results:

| Stock | MV | BL | Equal weight (1/N) |
|---|---:|---:|---:|
| 3034 | 24.38% | 18.13% | 16.67% |
| 2357 | 18.38% | 8.06% | 16.67% |
| 2454 | 12.89% | 19.13% | 16.67% |
| 2886 | 43.96% | 9.06% | 16.67% |
| 3711 | 0.40% | 17.12% | 16.67% |
| 2330 | 0.00% | 28.50% | 16.67% |

Source: [presentation_weights_normalized.csv](outputs/tables/presentation_weights_normalized.csv). Each portfolio sums to 100% before display rounding; the percentages shown may not total exactly 100%. Independently [refitted in-sample weights](outputs/tables/recomputed_in_sample_weights.csv) are saved separately.

These are historical price-return comparisons. The data do not include reinvested distributions, transaction costs, taxes, or corporate-action adjustment. Stock selection is retrospective, and the refitted portfolios use the same window for fitting and evaluation. The results do not establish an out-of-sample investable strategy.

## Folder structure

```text
portfolio optimization/
├── README.md                         Main English guide (GitHub landing page)
├── README_zh.md                      Traditional Chinese project guide
├── README_en.md                      Compatibility link to the English guide
├── PortfolioOptimization.Rproj       RStudio project settings
├── run.R                             Main R entry point
├── R/                                Five shared analysis modules
├── scripts/                          Installation, LSTM, report builder, requirements
├── tests/                            R regression checks and Python unit tests
├── data/
│   ├── stocks/                       30 original daily-price Excel workbooks
│   ├── etfs/                         10 original daily-price Excel workbooks
│   └── historical/ml_returns.xlsx    Original three-model forecast-path summaries
├── docs/                             Presentation, calculation notes, validation, cleanup records
├── outputs/
│   ├── tables/                       Recalculated analysis and model-summary CSVs
│   ├── figures/                      Analysis figures, pairwise CCFs, model forecasts
│   ├── models/                       RF/XGBoost and LSTM metrics and predictions
│   ├── full_run/2026-10-21/           Full-run logs and independent verification
│   ├── analysis.rds                   Saved R configuration and analysis objects
│   └── RUN_NOTES.txt                  Assumptions and R session/package information
├── reports/
│   ├── report_zh/                    Chinese narrative and PDF
│   ├── report_en/                    English narrative and PDF
│   ├── assets/                       Six composite report figures
│   └── …                             Report guide, source manifest, validation records
├── references/
│   ├── papers/                       Research paper cited by the project
│   └── figures/                      37 preserved historical figures
└── archive/                          Original submitted and relevant legacy source
```

`data/` and `references/figures/` preserve research inputs and original artwork. Generated analysis belongs in `outputs/`; generated report figures and PDFs belong in `reports/`. The public project includes analysis results and full-run evidence so the README links can be inspected directly. The `.gitignore` excludes R session files, Python caches, virtual environments, and temporary files. The `.gitattributes` preserves checked file bytes so platform newline conversion does not invalidate recorded SHA-256 hashes.

## Environment and setup

The complete run was verified with **R 4.6.1 for Windows**, **Python 3.10.10**, and **PyTorch 2.0.1 on CPU**. These are the tested versions, rather than a claim that every dependency combination is supported. Recorded R package versions and the local runtime setup are available in the [full-run evidence](outputs/full_run/2026-10-21/RUN_SUMMARY.md).

Open a terminal in this project folder. Ensure `Rscript` and `python` resolve to the intended installations, or use their full executable paths. RStudio users can open [PortfolioOptimization.Rproj](PortfolioOptimization.Rproj); old `.RData` workspaces are not loaded automatically.

```powershell
# Install all R dependencies, including models and ADF diagnostics.
Rscript --vanilla scripts/install_packages.R --all

# Install Python dependencies for LSTM and report construction.
python -m pip install -r scripts/requirements-lstm.txt -r scripts/requirements-reports.txt
```

R dependencies are `readxl`, `quadprog`, `igraph`, `tseries`, `randomForest`, and `xgboost`. Python requirements are maintained in [requirements-lstm.txt](scripts/requirements-lstm.txt) and [requirements-reports.txt](scripts/requirements-reports.txt). Installation requires network access; the analysis itself reads local files and does not fetch new market prices.

### Quick analysis: reuse saved model results

```powershell
Rscript --vanilla run.R
```

This recalculates descriptive statistics, stock screening, historical portfolio performance, MV/BL fits, and representative figures. It **does not retrain models**. When valid prediction CSVs exist in `outputs/models/`, it loads them to refresh the combined model table and forecast plots.

The equivalent RStudio call is:

```r
source("run.R", encoding = "UTF-8")
result <- run_project()
```

### Complete run: test, retrain, analyze, and rebuild reports

After installing dependencies, run the following in order:

```powershell
Rscript --vanilla tests/run_tests.R --models
python -B -m unittest discover -s tests -p test_lstm.py -v

# Train LSTM for all 22 stocks: 50 epochs per stock.
python scripts/train_lstm.py

# Train RF/XGBoost, load all three models, and plot every stock-pair CCF.
Rscript --vanilla run.R --train --all-pairs

# Build the two bilingual reports from saved analysis results.
python scripts/build_reports.py
```

LSTM is trained first so the R run can include all three models in one combined table and each stock's forecast panel. RF uses 500 trees per stock, XGBoost uses 10 rounds, and LSTM uses 50 epochs. Model seeds and settings are explicit in the source.

The report builder reads the 16 saved analysis CSVs and local workbooks; it does not retrain models. Its default font directory is `C:/Windows/Fonts`. On another system, provide the licensed Times New Roman and PMingLiU files listed in the [report guide](reports/README.md) through `--font-dir`. Review both editable report narratives when changing data or assumptions; the builder checks key numerical claims before producing the PDFs.

### Command options

| Entry point | Option | Effect |
|---|---|---|
| `run.R` | `--train` | Retrain RF and XGBoost for the 22 historical screened stocks |
| `run.R` | `--all-pairs` | Plot all 435 stock-pair CCFs instead of the representative stock pair |
| `run.R` | `--figure-format png` or `pdf` | Select the analysis figure format; default `png` |
| `run.R` | `--output-dir PATH` | Set the analysis output root, including its `models/` directory |
| `run.R` | `--help` | Show supported R command options |
| `train_lstm.py` | `--symbols 2330 --epochs 2` | Run a small single-stock smoke check |
| `train_lstm.py` | `--output-dir PATH` | Set the directory for the two LSTM CSVs |
| `train_lstm.py` | `--help` | Show root, lookback, chronological split, and seed options |
| `build_reports.py` | `--font-dir PATH` | Set the report font directory |

For example, `Rscript --vanilla run.R --figure-format pdf --output-dir outputs/pdf` writes vector analysis figures to a separate output root. To combine LSTM with a custom R output root, direct LSTM to that root's `models/` subdirectory. A smoke check uses the same filenames as full LSTM training, so use a separate `--output-dir` to preserve complete results.

## Data and calculation conventions

- **Raw coverage:** 40 price workbooks, generally covering 2019-01-02 through 2023-11-30, plus one historical ML workbook. Later starts or missing observations affect individual series; the aligned 30-stock panel contains 1,137 common closing-price observations.
- **Evaluation:** the six stocks and ten ETFs share 218 price observations, yielding 217 daily returns from 2023-01-03 through 2023-11-30. Dates are aligned; missing prices are not filled with zero.
- **Forecast target:** the previous 20 observed closing prices predict the next observed closing price. Observations are not necessarily consecutive calendar or trading days. Samples are split chronologically 80%/20%, and LSTM scaling is fitted on training data only.
- **Forecast sample counts:** 20 of the 22 screened stocks have 940 training and 235 test samples. Stock 2603 has 934/234 and stock 6669 has 899/225 because their histories are shorter.
- **Screening:** absolute Pearson correlations of log returns must be below 0.6 within a selected clique. Multiple maximum cliques are valid; the presentation's 22-stock list is preserved, and the recomputed deterministic selection is exported for comparison.
- **Historical allocations:** slide 45's rounded MV/BL weights are normalized before constructing buy-and-hold wealth. Performance is recalculated from prices, rather than copied from the slide.
- **Refitted allocations:** MV and BL are estimated and evaluated on the same 2023 window. Offline BL uses sample covariance, an equal-weight prior, and configured annual views/Omega. The original notebook used Yahoo data, market capitalization, Ledoit–Wolf covariance, and L2 regularization, so exact reproduction of that implementation is not claimed.

Detailed assumptions are centralized in [R/config.R](R/config.R) and explained in [REFACTOR_NOTES.md](docs/REFACTOR_NOTES.md).

## Outputs and their meaning

| Output | Interpretation |
|---|---|
| `tables/historical_ml_returns_percent.csv` | Original workbook values: changes between the first and last predicted prices, in percent |
| `tables/presentation_*.csv` | Normalized presentation weights, reconstructed historical wealth, and price performance |
| `tables/recomputed_in_sample_*.csv` | Newly refitted weights, wealth, and performance on the same evaluation window |
| `tables/mv_frontier.csv`, `bl_frontier.csv`, `bl_annual_returns.csv` | Model frontier coordinates and BL prior/view/posterior annual returns |
| `tables/combined_forecast_metrics.csv` | Newly trained RF/XGBoost/LSTM RMSE, MAE, predicted-path change, and split metadata |
| `models/forecast_{metrics,predictions}.csv` | RF/XGBoost metrics and dated predictions |
| `models/lstm_{metrics,predictions}.csv` | LSTM metrics and dated predictions |
| `figures/models/forecast_<symbol>.png` | Actual closes and all available model predictions for one stock |
| `analysis.rds`, `RUN_NOTES.txt` | Reusable analysis objects, assumptions, and execution environment |

Paths in the table above are relative to `outputs/`. The historical workbook and current retraining results represent different executions. Neither model's predicted-path change is a tradable return known at the beginning of its test period. Current retraining also cannot recover the missing historical per-stock RMSE records used to exclude stocks from the original final selection.

The number of generated analysis files depends on available model results and options:

| Run configuration | Analysis figures | Analysis table CSVs |
|---|---:|---:|
| Fresh default run, without saved model results | 16 | 15 |
| Default run with all 22 stocks' saved model results | 38 | 16 |
| Full run with complete models and `--all-pairs` | 472 | 16 |

The full 472 consist of **16 core figures + 434 additional stock-pair CCFs + 22 model forecast panels**. The core figures already contain one stock CCF and one ETF CCF, so there are 435 stock CCFs and one ETF CCF in total. These counts exclude the **four model CSVs**, full-run audit files, and the report builder's **six composite figures and two PDFs**. Rerunning a smaller workflow in an existing output directory does not remove previously generated extra pair plots, so the folder's total may exceed the files generated by that invocation.

## Source code guide

| File | Responsibility |
|---|---|
| [run.R](run.R) | Entry point, orchestration, validation/loading of results, and output saving |
| [R/config.R](R/config.R) | Dates, stock lists, historical weights, BL views, and shared parameters |
| [R/data.R](R/data.R) | Excel loading, alignment, returns, descriptive statistics, ADF tests, and correlation screening |
| [R/models.R](R/models.R) | Rolling windows, RF/XGBoost training, prediction validation, and loading saved results |
| [R/portfolio.R](R/portfolio.R) | MV/BL, efficient frontiers, buy-and-hold wealth, return, risk, and Sharpe |
| [R/plots.R](R/plots.R) | Shared PNG/PDF plotting, including forecasts, CCFs, and recurrence plots |
| [scripts/install_packages.R](scripts/install_packages.R) | Explicit R dependency installation |
| [scripts/train_lstm.py](scripts/train_lstm.py) | CPU LSTM training, chronological split, and training-only scaling |
| [scripts/build_reports.py](scripts/build_reports.py) | Numerical checks, composite color figures, bilingual PDFs, and source manifest |
| [tests/run_tests.R](tests/run_tests.R) | R calculation, alignment, loading, and optional real-model regression checks |
| [tests/test_lstm.py](tests/test_lstm.py) | Python windowing, chronology, scaling, and training checks |
| [PortfolioOptimization.Rproj](PortfolioOptimization.Rproj) | RStudio project configuration |

## Verified full run

The **2026-10-21** native run passed **32 R checks and 8 Python tests**, trained **22 stocks × 3 models**, and produced **66 metric rows and 15,477 dated test predictions**. Prediction dates, observed prices, RMSE, and MAE were independently checked against the source workbooks. All 472 generated PNGs passed image decoding checks, and both original 12-page color reports were rebuilt and inspected during that run.

The R main workflow took approximately **102 seconds**, and the full LSTM training approximately **148 seconds**, on the recorded local environment. These measurements exclude initial installation and report-layout inspection and are not runtime guarantees on other machines.

- [Full execution summary and model comparison](outputs/full_run/2026-10-21/RUN_SUMMARY.md)
- [R pipeline log](outputs/full_run/2026-10-21/r_full_pipeline.log) and [R test log](outputs/full_run/2026-10-21/r_tests.log)
- [LSTM execution log](outputs/full_run/2026-10-21/lstm_full_run.log)
- [Independent verification](outputs/full_run/2026-10-21/verification.json)
- [Project validation record](docs/VALIDATION.md) and [report validation](reports/VALIDATION.md)

The earlier WebR checks described in the validation history were superseded for execution coverage by this complete native run. Successful execution validates the configured workflow; the research limitations above still apply.

## References and archived material

[references/](references/) retains the cited research paper and **37 historical figures**: 30 stock decomposition plots, four ETF decomposition plots, two recurrence plots, and one MV frontier image. The original `3711 2311 復發圖.png` is retained as evidence because the provided raw data do not contain stock 2311; the current pipeline does not silently substitute another stock for it.

[archive/](archive/) preserves the original final submission's 12 source files in `final-submission-source.rar` and 14 relevant legacy scripts/notebooks in `legacy-source.zip`. These are recovery and provenance records; use the root entry points for the maintained workflow. Old R session files, duplicate nested archives, and unrelated attachments were removed during folder organization.

See the [archive guide](archive/README.md) for recovery details, the [folder cleanup record](docs/FOLDER_CLEANUP.md) for moves and deletions, and the [refactoring notes](docs/REFACTOR_NOTES.md) for calculation changes. Historical inventory paths in archive manifests describe the earlier folder layout.
