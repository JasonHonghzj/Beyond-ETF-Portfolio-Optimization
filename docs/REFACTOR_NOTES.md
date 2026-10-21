# 整理紀錄（2026-10-20）

## 依據與範圍

主依據為 `docs/presentation.pdf`（原名 `巨量資料分析_Final presentation.pdf`），尤其第 31–52 頁：探索、相關性、選股、20 天 rolling window、三種 ML、六股配置及 ETF 比較。另讀取 `archive/final-submission-source.rar`（原 `Final project/BDA_Final_Project_Team3_code.rar`）的 12 份正式程式；該壓縮檔包含 LSTM 訓練與正式 BL Notebook。

本檔記錄第一階段程式整理。依後續「整個資料夾只保留 final project 相關檔案」的要求，第二階段已移動相關資料、移除無關及重複附件，並將舊備份清理為 `archive/legacy-source.zip`，保留 14 份程式來源；工作階段、課堂歷史與重複巢狀 ZIP 不再保留。原始清冊仍作歷史紀錄，目前位置與刪除依據見 [資料夾清理紀錄](FOLDER_CLEANUP.md)。

## 合併與移除對照

| 原始檔案 | 整理後位置／處理理由 |
|---|---|
| `巨量Final.R` | 拆入 `R/data.R`、`R/plots.R`；刪除重複畫圖、AAPL／GOOG 未定義範例與路徑片段 |
| `巨量_交叉相關.R` | `R/plots.R`；每支股票只讀一次，按日期對齊，預設不產生 435 張重複配對圖 |
| `巨量_復發圖.R` | `R/plots.R`；明確定義 z-score、embedding=1、radius 的純量交叉復發矩陣，免除只畫圖所需的整套 CRQA 依賴 |
| `巨量_rolling_data.R` | `R/models.R`；保留 RF，移除後半不完整的 split_data／括號錯誤 |
| `巨量_XGB.R` | `R/models.R`；採正式 RAR 中的 lag 輸入，移除當日 close 預測自身及無效三引號片段 |
| `巨量_MV.R` | `R/portfolio.R`；移除外部全域 data、固定 218 列與重複最佳化 |
| `巨量_BL.R` | 移除錯誤命名實驗；其實是以平均股價為目標的 QP，正式 BL 整合至 `R/portfolio.R` |
| `巨量_累計報酬圖_效率曲線.R` | `R/portfolio.R`＋`R/plots.R`；集中效率前緣、資產權重與績效 |
| `巨量_配適圓餅圖.R` | `R/plots.R`；直接使用同一份具名權重，避免手動抄寫 |
| `巨量_報酬比較.R`、`巨量_風險比較圖.R` | `R/portfolio.R`＋`R/plots.R`；從同一份逐日淨值計算，不寫死報酬與風險 |
| `BL model/BL (1).py`、`BL model/Untitled1.ipynb` | 正式 BL 公式與功能移入 R；刪除重複 class、固定三個 view 與最佳化過程改 prior 的實驗 |
| `BL model/Untitled1.zip`、`BL model/Untitled1 (2).zip` | 內容均為已整理的 BL Notebook／Python 實驗，納入備份後移除 |
| 根目錄、`ETF/`、`stock_data/` 的 `.RData`／`.Rhistory` | 第一階段備份，第二階段從舊備份移除；避免保留舊全域變數與無關課堂紀錄 |
| 正式 RAR 的探索／模型／結果程式 | 功能併入上述模組；原 RAR 作歷史證據保留，不再另建一份會持續分歧的程式樹 |
| 正式 RAR 的 LSTM Notebook | `scripts/train_lstm.py`，保留原 2 層／32 hidden／Adam .01／50 epochs，刪除 demo、GRU 殘留與重複圖表 |

## 修正的計算與資料問題

- Excel 以欄名 `date`、`close` 讀取，代碼維持字串；移除依賴第 9 欄 `No` 的索引。
- 統一日期升冪、共同日期對齊，拒絕重複日期、缺失或非正收盤價。
- RF／XGB／LSTM 統一 20 個歷史收盤價預測下一日；原 LSTM 實際只有 19 天特徵，且縮放時用到測試資料，現已修正。
- 1,195 筆收盤價產生 1,175 個預測樣本，940／235 依時間切分；實際測試日期是 **2022-12-08 至 2023-11-30**，並非完整 2023 曆年。
- 預測保留日期、actual、predicted、RMSE 與 MAE。既存 RF／XGB／LSTM CSV 每次重跑都會驗證並合併，避免只剩最後訓練的一種模型；不符合來源或視窗的舊輸出會明確報錯。
- 使用初始資金權重計算 `sum(weight * price / first_price)`，取代直接把不同股價相加；買入後股數固定。
- 累積報酬改為淨值相對初始值減 1，取代 `cumsum(simple_return)`。
- 價格、報酬、風險及無風險利率不再混用百分比／小數。交易日基準統一為可設定的 252；實際 218 個價格觀測只有 217 個逐日報酬。
- `period_return` 為期間實現價格報酬；`annualized_return` 為幾何年化；波動為逐日簡單報酬標準差乘 `sqrt(252)`；Sharpe 使用年化算術平均超額報酬除年化波動。
- MV／BL 共用 long-only、總和 1 的最佳化與效率前緣；切點在網格附近連續細化，曲線、標記與權重一致。奇異共變異數會明示 ridge。
- BL prior 固定，不再隨最佳化候選權重改動；用線性方程求解，避免多次顯式反矩陣。
- 圖表集中管理裝置、配色、檔名及 PNG／PDF 格式；歷史權重圖與重估效率前緣有不同來源註記。零波動的 Sharpe 顯示 N/A。

## 與原簡報不同但已保留的資訊

1. 第 45 頁 MV 權重總和為 1.001，BL 為 0.993。歷史圖使用該頁數字正規化後的權重；不把四捨五入誤差當額外槓桿。2023-01-03 至 2023-11-30 重算 MV 價格報酬約 40.40%，BL 約 38.71%，1/N 約 39.57%。風險與 Sharpe 因統一定義及年化而不同。
2. 原正式 BL 使用 Yahoo 價格、Ledoit–Wolf covariance、執行時市值、L2、max_sharpe，而且後段 frontier 採不同目標。新 R 版使用本機價格、樣本 covariance、明示等權 prior、原年度 views 與自訂 Omega；保留可重現的重新估計流程，沒有宣稱精確重現原 BL 數字。原 Notebook 完整留在 RAR／備份中。
3. 獨立列舉確認有八組並列、各含 22 檔的最大低相關 clique，原簡報名單也是有效解。穩定字典序 tie-break 會把原名單中的 **6505 換成 1301**；輸出 `stock_selection_comparison.csv` 供檢查。歷史模型仍使用簡報原 22 股與最終 6 股；此差異不是原選股錯誤。
4. 第 39 頁 `3711/2311` 缺少 2311 原始資料，不能重新生成，原 PNG 現封存於 `archive/historical-results/figures/recurrence/`（2026-10-21 從 `references/figures/recurrence/` 移入）。不將 2317 假冒 2311；預設生成有資料的 2881/2882，以及原 R 程式的 2412/6505。
5. 復發圖為兩條各自 z-score 後的價格序列，矩陣 `abs(z_x[i]-z_y[j]) <= radius`，embedding=1。這是明確定義的純量交叉復發圖，不輸出或冒稱完整 CRQA 統計量。
6. `return_1.xlsx` 沒有日期；第二階段確認六欄皆可由保留的收盤價重建為每日簡單報酬後，已移除這份重複匯出。原 `三種ML的return.xlsx` 保留為 `data/historical/ml_returns.xlsx`；其原單位為百分比，輸出表名仍為 `historical_ml_returns_percent.csv`。
7. 簡報選股及配置是歷史研究設定；同一 2023 期間配適與評估屬樣本內比較。預測期間的首末價格差也不能當成期初已知的一年預測。未額外擴張為新的樣本外研究。

## 驗證

測試結果與執行環境另記錄於 `VALIDATION.md`。第二階段逐一核對 81 個移動檔案的 SHA-256，並依 `FOLDER_CLEANUP.json` 記錄刪除與移動，確保保留的研究資料、文件與圖稿內容一致。
