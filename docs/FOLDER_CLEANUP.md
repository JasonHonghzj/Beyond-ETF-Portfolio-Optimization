# 全資料夾整理紀錄（2026-10-20）

依「整個資料夾只保留 final project 相關檔案」整理，檢查了檔案內容、壓縮包內的成員、簡報引用與程式讀取路徑。沒有僅因程式未引用就刪除相關研究文件或歷史圖。

## 移除內容

| 原檔案 | 移除依據 |
|---|---|
| `Final project/presentation2.pdf` | 兩頁課堂繳交規範與 WAT／生統 RA 筆記，非期末報告 |
| `效率前緣圖/frontier plot.jpg` | AMZN、NFLX 等美股範例，非本案台股研究結果，未用於正式簡報 |
| `(A3-1)時報資訊 - 股票歷史資料和三年基金歷史資料_0329.zip` | 前期課程資料包，10 股日／週共 20 份；資料延至 2024-03，已由 final 的 2019–2023 富果 API 資料取代。屬被取代的前期資料，不標作完全無關 |
| `ETF/ETF.rar` | 前期 ETF 選單；四份與現存資料相同，另六檔不屬 final 的十檔 ETF，已由正式資料取代 |
| `stock_data/daily_.rar` | 30 個 Excel 逐一 SHA-256 與保留的原始行情完全一致 |
| `ETF/data.xlsx` | 十欄的所有非空收盤價均與原始逐檔資料一致，是不含日期的重複匯出 |
| `stock_data/stock_data.xlsx` | 三十欄的所有非空收盤價均與原始逐檔資料一致，是不含日期的重複匯出 |
| `return_1.xlsx` | 六欄皆與原始收盤價重建的每日簡單報酬一致，最大差異小於 5e-16；無須另保留不含日期的匯出 |

另以 `archive/legacy-source.zip` 替換原 `original-code-20261020.zip`。新檔保留 14 份專案來源：11 支 R、兩支 Python、一份 Notebook。已從舊備份移除六個 `.RData`／`.Rhistory` 及兩個巢狀 ZIP；其中重複 Notebook 不重存，唯一的 Python 匯出程式有取出保留。替換前已逐份核對內容雜湊。

因此本輪刪除八個不相關、已取代或重複的附件，另替換一個舊備份。沒有再把這些刪除附件打包回專案。

## 保留與分類

| 位置 | 內容 |
|---|---|
| `data/stocks/` | final 30 檔股票原始行情 |
| `data/etfs/` | final 十檔 ETF 原始行情 |
| `data/historical/ml_returns.xlsx` | 三種 ML 原研究結果，保留原數值 |
| `docs/presentation.pdf` | 正式簡報，僅改位置與檔名 |
| `references/papers/` | 正式簡報第 19、41、43 頁引用的 ETF／投資組合論文 |
| `references/figures/decomposition/` | 30 張股票、四張 ETF 的歷史分解圖；含 trend／seasonal／remainder，與新版趨勢圖不同 |
| `references/figures/recurrence/` | 兩張原始復發圖；其中 3711／2311 因缺少 2311 原始資料而無法重新生成，因此保留 |
| `references/figures/portfolio/mv.jpg` | 最終六股的原始 MV 前緣，作歷史結果對照 |
| `archive/final-submission-source.rar` | 原正式提交的十二份 R／Notebook，內容不變 |
| `archive/legacy-source.zip` | 整理前的十四份程式來源，不含舊工作階段或課堂歷史 |
| `outputs/` | 目前產生的圖表、數據表與分析物件 |

共 81 個檔案移至以上分類，逐檔以 SHA-256 確認內容未改。原 `ETF/`、`stock_data/`、`Final project/`、`效率前緣圖/` 的空目錄已移除。

程式的資料路徑同步更新於 `R/config.R`、`run.R`、Python LSTM 與測試；執行命令維持 `Rscript --vanilla run.R`。

完整舊新路徑、刪除理由與雜湊見 `FOLDER_CLEANUP.json`。`archive/original-manifest.json` 與 `cleanup-verification.json` 僅代表第一階段的歷史快照，不是現有路徑清單。

整理後重新通過 31 項 R 檢查、8 項 Python 測試及完整主流程，16 張圖正常產生；15 份 CSV 與移動前完全一致。Python LSTM 也從新路徑完成 2330、2 epochs 的 CLI 檢查。
