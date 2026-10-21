## abstract

This report reconstructs Beyond ETFs, a Spring 2024 course project combining stock screening, machine learning, and portfolio allocation. Local 2019-2023 closing-price records support a comparison of six-stock mean-variance (MV), Black-Litterman (BL), and equal-weight portfolios with ten ETFs over January 3-November 30, 2023. Using normalized historical allocations, their period price returns are 40.40%, 38.71%, and 39.57%, with Sharpe ratios of 2.584, 2.134, and 2.326. Each exceeds seven ETF returns, while MV has the strongest risk-adjusted result among the three portfolios. These outcomes do not establish universal ETF outperformance: 00757 returns 88.46%, and 00713 has lower volatility and a higher Sharpe ratio than MV. Re-estimation changes the BL-MV return ordering. The reconstruction therefore emphasizes sensitivity to allocation assumptions and distinguishes historical prediction summaries from executable forecasts. Full retraining validates execution of all three models across twenty-two stocks. Same-window estimation, retrospective selection, and unadjusted prices still limit the portfolio evidence to historical reconstruction and in-sample analysis.

## overview

Beyond ETFs was conducted in Spring 2024 for a big-data analytics course; the preserved presentation records the original group investigation. It studies whether screening individual stocks and applying allocation methods can offer an alternative to ETF holdings. The integration of forecasting and allocation relates to Day and Lin's robo-advisor framework [1]. This report was reconstructed and fully rerun on October 21, 2026 from the preserved presentation, local data, current code, and generated results. That verification date is separate from the original research term.

## objective

- Reconstruct the sequence from thirty candidate stocks to twenty-two screened stocks and six final holdings.
- Compare MV, BL, and equal weighting against ten ETFs using consistent return and risk definitions.
- Explain what the preserved forecasts, diagnostics, and re-estimated allocations support, including their reproducibility limits.

## scope

The report covers sixteen generated CSV tables and 472 PNG figures through result summaries, composite figures, and artifact catalogs. These include all 435 stock-pair CCFs, one ETF-pair CCF, and twenty-two three-model forecast panels. Historical allocations, archived prediction summaries, and current retraining remain separate. The presentation provides historical context; generated tables support the numerical comparisons.

## data

The inputs comprise daily closing-price workbooks for thirty stocks and ten ETFs, principally covering January 2019-November 2023. The original presentation identifies the Fugle API as its source. Series begin on different dates: all thirty stocks share 1,137 price observations from March 27, 2019, while the common forty-asset intersection contains 1,113 observations from May 3, 2019. No duplicate dates, missing closes, or nonpositive closes were found in these individual series. The comparison window is January 3-November 30, 2023, containing 218 prices and 217 daily returns. These are unadjusted price records.

## screening

Screening uses common-date stock log returns. A graph connects two stocks when their absolute correlation is strictly below 0.6; a maximum clique identifies a largest group satisfying that pairwise condition. Independent enumeration yields eight tied maximum cliques, each containing twenty-two stocks. The archived twenty-two-stock group is one valid maximum. Deterministic tie-breaking selects another group that replaces 6505 with 1301. The reconstruction retains the historical selection when describing the original forecasting and final portfolio sequence.

## forecasting

The archived workflow compares Random Forest (RF), XGBoost, and long short-term memory (LSTM) models. Current code constructs next-close targets from the preceding twenty observed closes and splits samples chronologically, using 80% for training. RF defaults to 500 trees and XGBoost to ten boosting rounds; LSTM remains a Python component. Scaling for the corrected LSTM workflow uses training data only. A test-period prediction path still incorporates subsequently observed lagged prices. Its first-to-last predicted-price change is therefore a retrospective path summary, rather than a return forecast available at the initial investment date.

## allocation

All portfolios allocate within the same historical six-stock universe: 3034, 2357, 2454, 2886, 3711, and 2330. Historical MV and BL weights are taken from the presentation, normalized to sum to one; equal weighting assigns one-sixth to each. A separate current calculation estimates long-only, fully invested efficient frontiers from the 2023 evaluation returns and selects their maximum-Sharpe allocations. BL combines an equal-weight equilibrium prior with six absolute annual views, using risk aversion 2.5, tau 0.05, and the configured diagonal view-uncertainty matrix. This offline prior is an explicit reconstruction assumption, not historical market capitalization. Consequently, re-estimation is a separate specification rather than an exact recovery of the archived notebook.

## measurement

Initial capital is one unit. Fixed shares purchased at the first observed prices generate buy-and-hold wealth, allowing portfolio weights to drift. Period return is final wealth divided by initial wealth minus one. Geometric annualized return uses 252 trading days and the observed 217-return horizon. Volatility is the daily simple-return standard deviation multiplied by the square root of 252. Sharpe uses the annualized arithmetic mean daily return less the 1.565% annual risk-free rate, divided by annualized volatility. Maximum drawdown is the most negative decline from a preceding wealth peak.

## main_results

For the normalized historical allocations, MV returns 40.40%, BL 38.71%, and equal weighting 39.57%. Their annualized volatilities are 15.10%, 17.82%, and 16.57%; Sharpe ratios are 2.584, 2.134, and 2.326. MV exceeds BL by 1.69 percentage points of period return while reducing volatility by 2.73 points. Its return advantage over equal weighting is smaller, at 0.83 points. MV also has the shallowest maximum drawdown among the three, at -8.59%, followed by equal weighting at -8.83% and BL at -10.56%. These comparisons describe the supplied interval and historical weights.

## risk_takeaways

The portfolios improve on different subsets of the benchmarks. MV, BL, and equal weighting exceed eight, six, and seven ETF Sharpe ratios, respectively, but each has lower volatility than only four of the ten ETFs. Thus, higher returns in this sample do not imply uniformly lower risk. MV has a smaller drawdown than six ETFs, whereas BL does so against four. The distinction matters because the project compares instruments with different price paths and exposures; no single return ranking summarizes their risk profiles.

## wealth_interpretation

The curves display cumulative price return, W(t)-1, starting at zero. Underlying buy-and-hold wealth starts at one; historical MV, BL, and equal weighting finish at approximately 1.4040, 1.3871, and 1.3957 units. The same dates and fixed-share convention underlie the performance table. Price growth excludes reinvested distributions and repeated portfolio rebalancing.

## benchmark_interpretation

Each historical portfolio exceeds seven of ten ETF period returns and trails 00757, 00733, and 00830. Their respective returns are 88.46%, 60.49%, and 50.77%. The return leader is therefore an ETF. Separately, 00713 combines 9.84% annualized volatility with a Sharpe ratio of 3.364, both more favorable than MV's corresponding values. These counterexamples qualify the project's Beyond ETFs framing.

## concentration

Historical MV places 43.96% in 2886 and 24.38% in 3034, totaling 68.33% in its two largest positions; 2330 receives zero weight. BL's two largest positions total 47.63%, while equal weighting's total 33.33%. The inverse sum of squared weights gives effective holdings of 3.30, 5.14, and 6.00, respectively. MV's stronger sample performance accompanies a more concentrated allocation, so six named holdings should not be interpreted as six equally influential risk contributions.

## frontiers

The re-estimated frontiers characterize expected return and volatility under their respective annual mean and covariance inputs. MV's tangency point has expected return 42.86%, volatility 14.87%, and model Sharpe 2.778. BL's corresponding values are 18.79%, 16.63%, and 1.036. Each frontier contains 151 reported points, including the refined tangency candidate. These model quantities differ from buy-and-hold realized statistics: they use fixed-weight mean-covariance calculations, whereas the wealth paths permit weights to drift. BL additionally uses posterior expectations and covariance. Frontier Sharpe ratios should therefore not be substituted for the performance-table Sharpe ratios.

## historical_ml

The preserved twenty-two-stock table reports percentage changes in RF, XGBoost, and LSTM prediction paths and their arithmetic averages. Nineteen averages are positive and three negative. The highest averages are 3034 at 65.65%, 2357 at 37.74%, and 2454 at 29.57%; 2603 is lowest at -22.68%. The top eight also include 6669, 2886, 2382, 3711, and 2330. The presentation states that 6669 and 2382 were removed for higher RMSE, leaving the final six. A complete historical per-stock RMSE table is absent from the default outputs, so the exclusion rule cannot be independently quantified. These archived path changes are not realized stock returns or executable period-start signals.

## model_validation

Full retraining on October 21, 2026 passed in native R 4.6.1 and Python: thirty-two R checks and eight Python tests. RF used 500 trees, XGBoost ten rounds, and LSTM fifty epochs across all twenty-two stocks. Combined outputs contain sixty-six metric rows and 15,477 test predictions. The table reports 2330's three model RMSEs from those outputs. These price-scale errors under chronological splits do not support direct error comparisons across stocks or establish an out-of-sample portfolio strategy.

## exploration

Price boxplots and the indexed six-stock trend panel describe the thirty-stock and ten-ETF input universe before allocation. Descriptive tables retain each symbol's observation count, date coverage, and price-level summaries. Differences in nominal price scales make direct boxplot heights unsuitable as return rankings. The selected-stock trend panel indexes each series to one at their common starting date, connecting exploration to the eventual holdings. Original decomposition plots are preserved as historical project outputs in archive/historical-results/figures/. These figures provide descriptive context without identifying the causes of price movements.

## stationarity

ADF calculations use lag ten and include the implementation's constant and linear trend. All forty log-return series reach the reported p-value lower bound of 0.01; this is not an exact p-value. Among price levels, only 2207 rejects the unit-root null at 5%, with p approximately 0.0242. Rejecting that null is evidence against a unit root under the test specification, not proof of stationarity.

## dependence

The thirty-stock correlation matrix makes the screening criterion inspectable. Within both the historical and deterministic twenty-two-stock groups, the largest absolute pairwise correlation is approximately 0.5988, between 2330 and 3711. It remains below the strict 0.6 cutoff and also occurs within the final six holdings. Low pairwise correlation can motivate diversification, but it does not imply statistical independence, stable future correlations, or low portfolio volatility. The matrix uses common-date log returns across the supplied sample rather than a pre-investment estimation window.

## clique_note

The difference between the archived selection and the deterministic selection reflects a tie among valid maximum solutions. It does not establish that the original twenty-two stocks were selected incorrectly. Retaining the historical group preserves the provenance of subsequent archived model summaries; reporting the alternate group exposes the screening procedure's non-unique outcome.

## diagnostics

The two cross-correlation examples use 1,194 shared daily log returns each. Their largest absolute correlations within lags -20 through 20 occur at lag zero: approximately 0.4325 for 2330/2317 and 0.6172 for 0050/00646. Contemporaneous association is the strongest displayed feature in these examples; the plots do not establish a predictive lead-lag relationship or causation.

## recurrence

The recurrence displays compare standardized scalar price series for 2881/2882 and 2412/6505. A point records proximity within radius 0.1, using embedding dimension one. This is a scalar cross-recurrence visualization, rather than a full cross-recurrence quantification analysis. Patterns are descriptive and do not identify causal relationships. The presentation's 3711/2311 example cannot be regenerated because a 2311 input series is absent; the reconstruction does not substitute another security.

## limitations

The central limitation is timing. Correlation screening uses the full supplied sample, final holdings are preserved retrospectively, and the re-estimated portfolios are fitted and evaluated over the same 2023 window. The results are consequently not an out-of-sample strategy backtest. The chronological forecasting split does not remove selection or allocation look-ahead elsewhere in the workflow. Moreover, historical prediction-path changes depend on observed lagged prices throughout the test interval and cannot be treated as initial-date investment forecasts.

The records contain unadjusted closes. Dividend reinvestment, transaction costs, taxes, and corporate-action adjustments are not incorporated, so reported growth is price performance rather than total investment return. January 3-November 30 is also shorter than a full calendar year; annualized values are transformations of that interval.

Historical weights were rounded, and BL reconstruction choices differ from the original notebook's online data, covariance, capitalization, and regularization assumptions. Full historical RMSE evidence remains unavailable; the completed current retraining cannot recover that historical exclusion record. No statistical significance, persistence across market regimes, or causal mechanism is established. These constraints support an auditable course-project reconstruction while leaving prospective investment effectiveness unresolved.

## reconstruction

Re-estimation changes the realized return ordering: BL returns 41.03%, MV 40.54%, and equal weighting 39.57%. MV still has lower volatility than BL, 15.16% versus 16.79%, and a higher Sharpe ratio, 2.581 versus 2.370. Historical and re-estimated weights are therefore reported separately. Independent calculations reproduce wealth, performance, correlations, and BL tables within floating-point tolerance. The October 21 full run generated sixteen CSV tables and 472 PNGs, including 435 stock-pair CCFs, one ETF-pair CCF, and twenty-two forecast panels. The default non-training entry point preserves saved results from all three models. Logs and validation evidence are retained under outputs/full_run/2026-10-21/.

## conclusion

The historical six-stock MV allocation provides the strongest return-risk combination among the three retained allocations during the supplied 2023 interval. Each portfolio exceeds most benchmark price returns, but several ETFs lead on return, volatility, or Sharpe ratio. Re-estimated BL's higher return further shows that the ranking depends on allocation assumptions. The project's contribution is a connected, inspectable workflow from data exploration through screening, forecasting, and portfolio comparison. A prospective evaluation would require selection and estimation using only information available before each decision, with explicit investment and accounting conventions.

## catalog

Tables 4 and 5 catalog sixteen CSV tables and 472 PNGs, grouping complete pairwise diagnostics and forecast panels.

## caption_performance

Historical allocations and ten ETF benchmarks over January 3-November 30, 2023. Returns use unadjusted closing prices; volatility and Sharpe are annualized using 252 trading days. MV, BL, and equal weighting use normalized presentation weights and fixed-share buy-and-hold wealth. Percentage values and Sharpe ratios measure different aspects of performance.

## caption_wealth

Cumulative price returns, W(t)-1, start at zero on January 3, 2023, for three historical allocations and ten ETF benchmarks through November 30. Underlying buy-and-hold wealth is rebased to one. Portfolio and ETF panels share the evaluation dates; terminal plotted returns match the performance table. Colors, line styles, and markers distinguish the series.

## caption_weights

Initial weights for the six historical holdings under MV, BL, and equal weighting, alongside their separately re-estimated counterparts. Historical rounded weights are normalized before use. The comparison highlights concentration and specification sensitivity. Re-estimation uses the evaluation window itself and should not be read as a prospective allocation recommendation.

## caption_frontiers

Long-only annual efficient frontiers for re-estimated MV and BL specifications. Markers identify the global minimum-variance and maximum-Sharpe allocations under each model's inputs. Expected returns and covariance-based risk characterize the optimization problem; they are distinct from the drifting-weight buy-and-hold return and Sharpe statistics reported elsewhere.

## caption_ml

Archived prediction-path percentage changes for twenty-two stocks, comparing RF, XGBoost, LSTM, and their average. An asterisk identifies the final six; (drop) identifies excluded top-eight candidates. These summarize sequences of one-step predictions, not realized returns. The presentation supplies the stated RMSE-based exclusion of 6669 and 2382.

## caption_eda

Closing-price boxplots for all thirty stocks and ten ETFs, with six selected stocks' trends indexed to one at their common starting date. Boxplots suppress outlier markers. Nominal price differences affect distribution scales and do not rank investment returns. Asset coverage and descriptive statistics appear in companion source tables.

## caption_correlations

Common-date log-return correlations for thirty candidate stocks. A luminance-monotonic cividis scale shows signed correlation from -1 to 1, supporting grayscale reading and inspection of the absolute-correlation threshold of 0.6. Both preserved and deterministic twenty-two-stock groups satisfy the threshold, and eight maximum groups tie. Correlation measures sample association; it does not establish independence or future diversification effectiveness.

## caption_diagnostics

Cross-correlation functions for 2330/2317 and 0050/00646, plus scalar cross-recurrence matrices for 2881/2882 and 2412/6505. Cross-correlation uses log returns; recurrence uses standardized prices, embedding one, and radius 0.1. The panels illustrate different forms of dependence and similarity without demonstrating forecasting ability or causal relationships.

## caption_recomputed

Performance of historical and re-estimated allocations under the same January-November 2023 price-wealth convention. Re-estimated BL has the higher period return, while MV retains lower volatility and higher Sharpe. The historical and re-estimated rows represent separate specifications; using the evaluation window for estimation makes this comparison in-sample.

## caption_datasets

Sixteen output CSV tables include historical evidence, portfolio reconstruction, and sixty-six newly trained model metrics.

## caption_original_figures

Catalog of 472 PNGs: sixteen core figures, 434 additional stock-pair CCFs, and twenty-two three-model forecast panels.
