# 報告驗證 / Report validation

檢查日期 / Review date: **2026-10-21**

本紀錄涵蓋中英文兩份署名報告，**每份 12 頁，共 24 頁**。檢查項目包含版面、字型、作者順序、metadata 及來源／產出雜湊；六組圖另以彩色與灰階檢視線型、標記及色階。

This record covers the two attributed Chinese and English reports, with 12 pages each and 24 pages in total. Checks cover layout, fonts, author order, metadata, and source/output hashes, together with color and grayscale inspection of the six shared figure groups.

## 產出與版面 / Outputs and layout

| 檢查 / Check | 結果 / Result |
|---|---|
| 中文及英文 PDF | 兩份署名報告；各 12 頁：正文 11 頁、參考文獻 1 頁；不設附錄 |
| 紙張與文字區 | 全部 24 頁為 612 × 792 pt（US Letter），文字位於置中 504 × 648 pt 區域 |
| 雙欄 | 欄寬 240.12 pt，欄距 23.76 pt（0.33 in）；整頁寬度的圖表跨欄排版 |
| 文字 | 本文、表格、圖說 10 pt / 12 pt；標題 11 或 14 pt；未縮小文字以塞入頁面 |
| 字型 | 全部實際使用的 Times New Roman、PMingLiU 及 Times 項目符號均內嵌；可擷取文字最小 10 pt |
| 文字邊界 | 全部 24 頁逐字幾何檢查通過，邊界容差 0.5 pt，無文字越界 |
| 作者及年代 | 中文署名順序為蘇柏諺、洪稚鈞、佘梓平、黃纓婷、陳依琪、林岱融；英文對應為 Bo-Yan Su, Zhi-Jun Hong, Tzu-Ping She, Ying-Ting Huang, I-Chi Chen, Tai-Jung Lin，Zhi-Jun Hong 維持第二位；署名版列 Spring 2024 |
| 首頁格式一致性 | 中英文均為兩行研究標題，其下依序列作者、系所及課程／學期／指導教授合併資訊，共三行；最後一行均為 Big Data Analytics Final Project \| Spring 2024 \| Advised by Prof. Shun-Lin Jeng，使用置中 10 pt 一般字體 |
| 中英文幾何核對 | 兩行研究標題及三行首頁資訊的對應位置、字級、字體樣式與間距一致；末頁文獻各字元的文字與位置也完全一致 |
| 作者單位與指導教授 | 國立成功大學統計學系／Department of Statistics, National Cheng Kung University, Taiwan.；兩版皆在合併資訊列以 Advised by Prof. Shun-Lin Jeng 註明指導教授；六位作者順序不變 |
| 參考文獻 | 最後一頁僅列 Day 與 Lin（2019）研究論文 [1]，內文引用編號一致；不列專題簡報、自製圖表、程式產出或格式資源，也不附版面與封存說明 |
| 頁碼及文字擷取 | 全部 24 頁頁碼正確；文字可擷取，關鍵數字及作者順序核對通過 |
| 彩色與灰階 | 保留彩色、線型或標記；MV／BL／1/N 為藍／橘／綠。cividis 相關矩陣固定 −1 至 1；256 色取樣的相對亮度嚴格遞增，灰階可辨識色階、線型與標記 |
| 最終視覺檢查 | Poppler 重新渲染兩份 PDF 共 24 頁，核對一致的標題及首頁資訊、指導教授、精簡參考文獻頁與整體版面，未見裁切、重疊或圖例遮擋 |

圖 1 顯示 `W(t)-1`（起點 0），底層期初淨值為 1。圖中文字以 300 dpi 點陣化，其字級不屬於 PDF 文字擷取檢查，已另作視覺核對。兩份報告的第 4–9 頁涵蓋六組共同圖像，均完成彩色與灰階辨識檢視。

報告採用 [OSDI 2024 投稿範本](https://www.usenix.org/conference/osdi24/requirements-authors)。

The reports use the [OSDI 2024 submission template](https://www.usenix.org/conference/osdi24/requirements-authors). Both retain a two-line research title, followed by three centered lines for authors, department, and “Big Data Analytics Final Project | Spring 2024 | Advised by Prof. Shun-Lin Jeng”. The combined final line uses identical English wording and regular 10-point type in both reports. Corresponding front-matter positions, sizes, styles, and spacing match. The six-author order is unchanged. The final References page contains only Day and Lin's 2019 research paper, numbered [1], with corresponding in-text citations. Layout, fonts, text boundaries, author metadata, page numbering, and source/output hashes are checked across all 24 pages. The six shared figure groups are also reviewed in color and grayscale.

## 數值及來源 / Numerical evidence and provenance

- 16 份 CSV 與 472 張分析 PNG 全部納入報告清冊；PNG 包含 16 張核心圖、434 張額外股票配對 CCF 及 22 張三模型預測圖（合計 435 組股票 CCF、一組 ETF CCF）。40 份原始價格 Excel 與一份歷史 ML Excel 均保留。
- 獨立從原始價格核對歷史買入持有淨值、績效、相關矩陣及 BL prior／posterior，最大數值差異小於 `8e-15`。
- 報告產製程式另核對 218 筆評估價格、歷史淨值、三種配置期間報酬及相對 10 檔 ETF 的勝出數。
- 37 張自行產生的歷史圖現封存於 [archive/historical-results/](../archive/historical-results/README.md)，與外部文獻分開；[搬移清冊](../archive/historical-results/figure_manifest.json)保留舊新路徑及逐檔 SHA-256。
- [report_manifest.json](report_manifest.json) 保存原始證據、分析程式、產製程式、兩份敘述來源、37 張封存圖及其清冊的 SHA-256；596 筆來源與兩份 PDF、六張整合圖共 8 筆產出雜湊均重新核對一致。
- [validation.json](validation.json) 記錄兩文件、24 頁的紙張尺寸、字型、字級、邊界、頁碼及作者檢查結果。

Historical MV / BL / 1/N price returns are **40.4048% / 38.7129% / 39.5722%**, each exceeding seven of ten ETF returns. The report retains counterexamples, including 00757's higher return and 00713's lower volatility and higher Sharpe.

## 驗證範圍 / Scope

2026-10-21 已完成原生 R 4.6.1 與 Python 全流程執行，通過 32 項 R 檢查及 8 項 Python 測試；RF（500 棵樹）、XGBoost（10 rounds）與 LSTM（50 epochs）皆完成歷史選股名單的 22 股重訓。合併表含 66 筆模型指標，三模型預測合計 15,477 筆；2330 的 RF／XGBoost／LSTM RMSE 分別為 9.9145／10.2377／15.1320。RMSE 依價格尺度計算，不用來跨股直接排名模型。

完整執行證據保留於 [outputs/full_run/2026-10-21/](../outputs/full_run/2026-10-21/)：`r_execution.json`、`r_tests.log`、`r_full_pipeline.log`、`lstm_full_run.log`、`lstm_full_run_validation.json`。原生 R 的 `run.R --train --all-pairs` 成功完成；LSTM 22 股訓練耗時 147.62 秒。報告建置本身只讀取已存結果；預設不重訓分析入口也會保留三模型的已存結果。市場資料期間未延長，詳見 [專案驗證紀錄](../docs/VALIDATION.md)。

Full native R 4.6.1 and Python execution passed 32 R checks and eight Python tests. All 22 stocks were retrained with RF (500 trees), XGBoost (10 rounds), and LSTM (50 epochs), yielding 66 metric rows and 15,477 test predictions. This validates execution under the configured chronological splits; it does not establish an out-of-sample portfolio strategy or recover missing historical RMSE exclusion records.

The report describes historical reconstruction and in-sample comparisons, not a verified out-of-sample trading strategy. Unadjusted closing prices exclude reinvested distributions, costs, taxes, and corporate-action adjustment. Historical full-stock RMSE exclusion records are unavailable, and the offline BL specification differs from the original notebook. These limits appear in both reports.
