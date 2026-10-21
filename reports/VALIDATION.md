# 報告驗證 / Report validation

檢查日期 / Review date: **2026-10-21**

本次新增署名／匿名四份版本、調整作者順序及相關矩陣色階後，**四份共 48 頁的版面、字型、作者與匿名資訊檢查均通過**。全部頁面已渲染核對，六組圖另以灰階檢視線型、標記及色階；下列記錄適用於本次四份最終 PDF。

All four attributed/anonymous versions passed the fresh 48-page review after revising the author order and correlation color scale. Anonymization and grayscale figure readability were also checked.

## 產出與版面 / Outputs and layout

| 檢查 / Check | 結果 / Result |
|---|---|
| 中文及英文 PDF | 各有署名課程版及匿名版，共四份；各 12 頁：正文 11 頁、參考文獻 1 頁；不設附錄 |
| 紙張與文字區 | 全部 48 頁為 612 × 792 pt（US Letter），文字位於置中 504 × 648 pt 區域 |
| 雙欄 | 欄寬 240.12 pt，欄距 23.76 pt（0.33 in）；整頁寬度的圖表跨欄排版 |
| 文字 | 本文、表格、圖說 10 pt / 12 pt；標題 11 或 14 pt；未縮小文字以塞入頁面 |
| 字型 | 全部實際使用的 Times New Roman、PMingLiU 及 Times 項目符號均內嵌；可擷取文字最小 10 pt |
| 文字邊界 | 全部 48 頁逐字幾何檢查通過，邊界容差 0.5 pt，無文字越界 |
| 作者及年代 | 署名兩版皆六位同序：蘇柏諺、洪稚鈞、佘梓平、黃纓婷、陳依琪、林岱融；英文第二位為 Zhi-Jun Hong，其餘保留中文；署名版列 Spring 2024 |
| 匿名資訊 | 兩匿名版的 Author metadata 為空、標題中性；全文及 metadata 無六人姓名、課程、教師、Spring 2024、原專題題名、使用者路徑或儲存庫識別；外部 Day／Lin 文獻及關鍵數據保留 |
| 頁碼及文字擷取 | 全部 48 頁頁碼正確；文字可擷取，關鍵數字、作者順序及匿名狀態核對通過 |
| 彩色與灰階 | 保留彩色、線型或標記；MV／BL／1/N 為藍／橘／綠。cividis 相關矩陣固定 −1 至 1；256 色取樣的相對亮度嚴格遞增，灰階可辨識色階、線型與標記 |
| 最終視覺檢查 | Poppler 渲染四份 PDF 共 48 頁；英文 24 頁、中文署名 12 頁及五張變動匿名頁逐頁檢視，另七張匿名頁與署名渲染雜湊相同；未見裁切、重疊或圖例遮擋 |

圖 1 顯示 `W(t)-1`（起點 0），底層期初淨值為 1。圖中文字以 300 dpi 點陣化，其字級不屬於 PDF 文字擷取檢查，已另作視覺核對。四個版本各自的第 4–9 頁另以 Poppler 灰階渲染，六組共同圖像亦完成灰階辨識檢視。版面依 [reports/README.md](README.md) 所連結規範。

署名課程版供作者留存；匿名版回應 [OSDI 2024 雙盲作者要求](https://www.usenix.org/conference/osdi24/requirements-authors)，避免署名與雙盲規則衝突。這是版本區分及版面參照，不表示實際投稿，也不保證會議接受。

The attributed course versions preserve the requested six-author order. Separate anonymous versions address the [OSDI 2024 double-blind requirements](https://www.usenix.org/conference/osdi24/requirements-authors). Fresh layout, font, text-boundary, author/metadata, and source/output-hash checks passed for all 48 pages. All pages were covered by visual inspection or identical-render comparison, and all six common figure pages were checked in grayscale. This does not imply an actual submission or guarantee conference acceptance.

## 數值及來源 / Numerical evidence and provenance

- 16 份 CSV 與 472 張分析 PNG 全部納入報告清冊；PNG 包含 16 張核心圖、434 張額外股票配對 CCF 及 22 張三模型預測圖（合計 435 組股票 CCF、一組 ETF CCF）。40 份原始價格 Excel 與一份歷史 ML Excel 均保留。
- 獨立從原始價格核對歷史買入持有淨值、績效、相關矩陣及 BL prior／posterior，最大數值差異小於 `8e-15`。
- 報告產製程式另核對 218 筆評估價格、歷史淨值、三種配置期間報酬及相對 10 檔 ETF 的勝出數。
- [report_manifest.json](report_manifest.json) 保存原始證據、分析程式、產製程式及兩份敘述來源的 SHA-256；558 筆來源與四份 PDF、六張整合圖共 10 筆產出雜湊均重新核對一致。
- [validation.json](validation.json) 已記錄本次四文件、48 頁的紙張尺寸、字型、字級、邊界、頁碼、作者及匿名檢查結果。

Historical MV / BL / 1/N price returns are **40.4048% / 38.7129% / 39.5722%**, each exceeding seven of ten ETF returns. The report retains counterexamples, including 00757's higher return and 00713's lower volatility and higher Sharpe.

## 驗證範圍 / Scope

2026-10-21 已完成原生 R 4.6.1 與 Python 全流程執行，通過 32 項 R 檢查及 8 項 Python 測試；RF（500 棵樹）、XGBoost（10 rounds）與 LSTM（50 epochs）皆完成歷史選股名單的 22 股重訓。合併表含 66 筆模型指標，三模型預測合計 15,477 筆；2330 的 RF／XGBoost／LSTM RMSE 分別為 9.9145／10.2377／15.1320。RMSE 依價格尺度計算，不用來跨股直接排名模型。

完整執行證據保留於 [outputs/full_run/2026-10-21/](../outputs/full_run/2026-10-21/)：`r_execution.json`、`r_tests.log`、`r_full_pipeline.log`、`lstm_full_run.log`、`lstm_full_run_validation.json`。原生 R 的 `run.R --train --all-pairs` 成功完成；LSTM 22 股訓練耗時 147.62 秒。報告建置本身只讀取已存結果；預設不重訓分析入口也會保留三模型的已存結果。市場資料期間未延長，詳見 [專案驗證紀錄](../docs/VALIDATION.md)。

Full native R 4.6.1 and Python execution passed 32 R checks and eight Python tests. All 22 stocks were retrained with RF (500 trees), XGBoost (10 rounds), and LSTM (50 epochs), yielding 66 metric rows and 15,477 test predictions. This validates execution under the configured chronological splits; it does not establish an out-of-sample portfolio strategy or recover missing historical RMSE exclusion records.

The report describes historical reconstruction and in-sample comparisons, not a verified out-of-sample trading strategy. Unadjusted closing prices exclude reinvested distributions, costs, taxes, and corporate-action adjustment. Historical full-stock RMSE exclusion records are unavailable, and the offline BL specification differs from the original notebook. These limits appear in both reports.
