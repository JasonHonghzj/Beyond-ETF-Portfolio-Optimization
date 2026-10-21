# 超越 ETF：機器學習與投資組合分析

繁體中文｜[English](README.md)

本專案為 **Spring 2024（2024 年春季學期）巨量資料分析課程期末專題**，以臺灣股票與 ETF 歷史資料，串接相關性選股、價格預測及投資組合配置。分析以 R 為主，Python 負責 PyTorch LSTM 與中英文報告產製。

市場資料截止於 **2023-11-30**。2026 年的程式重構、資料夾整理、報告重建與 **2026-10-21 完整重跑**，屬於維護及驗證，沒有延長市場資料期間。

## 專案概覽

    30 檔股票＋10 檔 ETF
      → 探索分析、ADF、相關性／交叉相關／交叉復發
      → 低相關選股（任兩股對數報酬的 |r| < 0.6）
      → 簡報原始 22 股名單與 RF／XGBoost／LSTM 逐筆預測
      → 簡報最終六股
      → MV／Black–Litterman／等權重配置，對照 10 檔 ETF

最終六股為 **3034、2357、2454、2886、3711、2330**。歷史選股及權重沿用原簡報；重新估計的配置與 2026 年模型重訓結果另行保存，避免將不同執行批次混為同一個回測。

| 從這裡開始 | 內容 |
|---|---|
| [正式簡報](docs/presentation.pdf) | Spring 2024 的原始研究設計與結果 |
| [中文報告](reports/report_zh/report_zh.pdf)／[英文報告](reports/report_en/report_en.pdf) | 含作者的課程報告：摘要、概述、目標、方法、結果、彩色圖表與限制 |
| [中文匿名版](reports/report_zh/report_zh_anonymous.pdf)／[英文匿名版](reports/report_en/report_en_anonymous.pdf) | 另行移除署名與身份線索的版本 |
| [報告說明](reports/README.md) | 作者資訊、版面、可編輯來源、字型與重建方式 |
| [完整執行摘要](outputs/full_run/2026-10-21/RUN_SUMMARY.md) | 實際命令、日誌、耗時與 22 股模型比較 |
| [模型比較 CSV](outputs/full_run/2026-10-21/model_comparison.csv) | 每股 RF／XGBoost／LSTM 的測試誤差 |

兩份署名版均列六位組員，**洪稚鈞／Zhi-Jun Hong 排第二位**；英文版依序列為 **Bo-Yan Su、Zhi-Jun Hong、Tzu-Ping She、Ying-Ting Huang、I-Chi Chen、Tai-Jung Lin**，英文姓名均將名字放在姓氏之前。另提供中英匿名版，以區分課程署名與 double-blind 匿名需求。四份 PDF 各 12 頁，依 OSDI 2024 的等效雙欄版面編排；不代表曾投稿或獲該會議錄取。

## 主要結果

以下為 **2023-01-03 至 2023-11-30** 的歷史配置重建：將簡報第 45 頁的四捨五入權重正規化，再按初始股數買入持有。

| 歷史配置 | 期間價格報酬 | 年化波動 | Sharpe |
|---|---:|---:|---:|
| 均值—變異數（MV） | 40.4048% | 15.0980% | 2.584 |
| Black–Litterman（BL） | 38.7129% | 17.8242% | 2.134 |
| 等權重（1/N） | 39.5722% | 16.5717% | 2.326 |

來源：[歷史價格績效表](outputs/tables/presentation_price_performance.csv)。三種配置的期間報酬各高於 **7／10 檔 ETF**，但未全面超越 ETF：00757 報酬更高，00713 波動更低且 Sharpe 更高。年化使用 252 個交易日，年度無風險利率為 1.565%。

這些結果是歷史價格報酬比較。資料未納入配息再投入、成本、稅費及公司行動調整；選股具有歷史選擇因素，重新配置又使用同期間估計與評價，不能解讀為已驗證的樣本外可投資策略。

## 資料夾結構

    portfolio optimization/
    ├── README.md                         英文主要專案說明（GitHub 首頁）
    ├── README_zh.md                      繁體中文專案說明
    ├── README_en.md                      英文說明相容連結
    ├── PortfolioOptimization.Rproj       RStudio 專案設定
    ├── run.R                             R 主入口
    ├── R/                                五個共用分析模組
    ├── scripts/                          套件安裝、LSTM、報告產製與依賴清單
    ├── tests/                            R 回歸檢查與 Python 單元測試
    ├── data/
    │   ├── stocks/                       30 檔股票原始日資料 Excel
    │   ├── etfs/                         10 檔 ETF 原始日資料 Excel
    │   └── historical/ml_returns.xlsx    原研究三模型預測路徑變動彙總
    ├── docs/                             正式簡報、計算差異、驗證與整理紀錄
    ├── outputs/
    │   ├── tables/                       分析表與合併模型指標 CSV
    │   ├── figures/                      分析圖、配對 CCF 與逐股預測圖
    │   ├── models/                       RF／XGBoost 與 LSTM 指標、預測 CSV
    │   ├── full_run/2026-10-21/           完整執行日誌及獨立核對紀錄
    │   ├── analysis.rds                   R 設定與分析物件
    │   └── RUN_NOTES.txt                  假設與 R 套件／執行環境
    ├── reports/
    │   ├── report_zh/                    中文敘述來源、署名 PDF、匿名 PDF
    │   ├── report_en/                    英文敘述來源、署名 PDF、匿名 PDF
    │   ├── assets/                       六張報告整合圖
    │   └── …                             報告說明、來源清冊與版面驗證
    ├── references/
    │   ├── papers/                       簡報引用的研究論文
    │   └── figures/                      37 張保留的歷史圖稿
    └── archive/                          正式提交與相關舊來源封存

原始研究輸入放在 data/，歷史圖稿放在 references/figures/；重算分析放在 outputs/，報告圖與 PDF 放在 reports/。公開專案一併保留分析產出與完整執行證據，讓 README 連結可直接查閱；.gitignore 僅排除 R 工作階段、Python 快取、虛擬環境與暫存檔。.gitattributes 保留原始位元內容，避免換行轉換使來源清冊的 SHA-256 失效。

## 環境與安裝

完整流程已在 **Windows、R 4.6.1、Python 3.10.10、PyTorch 2.0.1 CPU** 驗證。這是實際測試組合，不代表任意舊版或套件組合均已驗證；完整版本見 [專案驗證紀錄](docs/VALIDATION.md)。

在專案根目錄開啟終端機，確認 Rscript 與 python 指向預期的安裝位置。RStudio 可開啟 [PortfolioOptimization.Rproj](PortfolioOptimization.Rproj)，不會自動載入舊 .RData。

    Rscript --vanilla scripts/install_packages.R --all
    python -m pip install -r scripts/requirements-lstm.txt -r scripts/requirements-reports.txt

R 套件為 readxl、quadprog、igraph、tseries、randomForest、xgboost。Python 依賴分別列於 [LSTM requirements](scripts/requirements-lstm.txt) 與 [報告 requirements](scripts/requirements-reports.txt)。安裝套件需要網路；分析與訓練讀取本地檔案，不下載新的市場行情。

### 快速分析：重用已存模型

    Rscript --vanilla run.R

此命令重算描述統計、選股、歷史投組績效、MV／BL 配置與代表性圖表，**不重新訓練模型**。outputs/models/ 若已有有效預測，會載入並更新合併指標及逐股模型比較圖。

RStudio 亦可執行：

    source("run.R", encoding = "UTF-8")
    result <- run_project()

### 完整重現：測試、重訓、分析與報告

先安裝依賴，再依序執行：

    Rscript --vanilla tests/run_tests.R --models
    python -B -m unittest discover -s tests -p test_lstm.py -v

    python scripts/train_lstm.py
    Rscript --vanilla run.R --train --all-pairs

    python scripts/build_reports.py

先跑 LSTM，再跑 R，讓一次 R 主流程載入三種模型。正式設定為每股 **RF 500 trees、XGBoost 10 rounds、LSTM 50 epochs**，涵蓋原始篩選名單的 22 股，種子與其他參數明示於程式。

報告程式讀取根目錄 outputs/ 內已存分析結果，不會重訓。若發現模型輸出，會要求完整且一致的 22 股 × 3 模型資料；單股或未完成輸出不能冒充完整報告證據。修改資料、估計設定或結果時，也須審查中英文敘述來源。

報告字型預設讀取 C:/Windows/Fonts。其他系統須透過 --font-dir 提供合法的 Times New Roman 與 PMingLiU 字型，檔名及細節見 [報告重建說明](reports/README.md)。

### 常用參數與另存輸出

| 入口 | 參數 | 用途 |
|---|---|---|
| run.R | --train | 重新訓練 RF／XGBoost；LSTM 仍由 Python 獨立執行 |
| run.R | --all-pairs | 產生 30 股全部 435 組 CCF，另保留 ETF 配對 |
| run.R | --figure-format png 或 pdf | 分析圖格式，預設 PNG |
| run.R | --output-dir PATH | 分析輸出根目錄，內含 tables／figures／models |
| run.R | --help | 顯示完整 R 命令選項 |
| train_lstm.py | --symbols 2330 --epochs 2 | 單股快速檢查；請搭配獨立輸出資料夾 |
| train_lstm.py | --output-dir PATH | LSTM 的兩份 CSV 所在目錄 |
| train_lstm.py | --help | 檢視 root、lookback、切分比例與 seed 選項 |
| build_reports.py | --font-dir PATH | 指定報告字型目錄 |

單股檢查另存，避免覆寫正式 22 股結果：

    python scripts/train_lstm.py --symbols 2330 --epochs 2 --output-dir outputs/smoke/models

自訂分析輸出時，LSTM 指向該根目錄的 models 子目錄：

    python scripts/train_lstm.py --output-dir outputs/demo/models
    Rscript --vanilla run.R --train --output-dir outputs/demo

    Rscript --vanilla run.R --figure-format pdf --output-dir outputs/pdf

--figure-format pdf 產生的是分析圖，不是研究報告。報告產製程式固定讀取專案根目錄的 outputs/，不會直接改讀上述 demo 或 pdf 子目錄。

## 資料與計算口徑

- **原始資料：**40 份價格 Excel 加一份歷史 ML Excel。程式按欄名讀取 date、close，檢查重複日期、缺值及非正價格，再依分析對象取共同日期；不補成零報酬。
- **歷史範圍：**一般序列為 2019-01-02 至 2023-11-30；部分序列較晚開始或缺少觀測。30 股共同資料包含 1,137 筆價格。
- **投組窗口：**六股與十檔 ETF 在 2023-01-03 至 2023-11-30 有 218 筆共同價格，產生 217 筆日報酬。
- **預測設計：**以前 20 筆觀測收盤價預測下一筆觀測收盤價，依時間切分 80%／20%；觀測不保證為連續日曆日或交易日，LSTM 縮放只使用訓練資料。
- **模型樣本：**20 股各有 940／235 筆訓練／測試樣本；2603 為 934／234，6669 為 899／225。測試起點分別為 2022-12-08、12-09、12-22，皆至 2023-11-30。
- **相關性選股：**以對數報酬的絕對 Pearson 相關係數小於 0.6 建立 clique。多組最大解均有效；保留原簡報名單，另輸出決定性的重算名單供比較。
- **歷史權重：**簡報四捨五入 MV／BL 權重各自正規化，再計算固定初始股數的買入持有淨值。
- **重新配置：**MV／BL 在同一 2023 年窗口估計及評價。離線 BL 使用樣本共變異數、等權 prior、原年度 views／Omega，與原 notebook 的 Yahoo、市值、Ledoit–Wolf 及 L2 流程不同。

共用設定見 [R/config.R](R/config.R)，方法差異及未能重建的部分見 [計算與重構說明](docs/REFACTOR_NOTES.md)。

## 輸出如何閱讀

下表路徑以 outputs/ 為起點：

| 輸出 | 用途與解讀 |
|---|---|
| tables/historical_ml_returns_percent.csv | 原研究三模型預測路徑首末變動，單位為百分比 |
| tables/presentation_*.csv | 歷史正規化權重、買入持有淨值與價格績效 |
| tables/recomputed_in_sample_*.csv | 新估計權重、淨值及同窗口績效 |
| tables/mv_frontier.csv、bl_frontier.csv、bl_annual_returns.csv | 效率前緣與 BL 年度 prior／view／posterior |
| tables/combined_forecast_metrics.csv | 新重訓 RMSE、MAE、預測路徑變動、時間切分資訊 |
| models/forecast_metrics.csv、forecast_predictions.csv | RF／XGBoost 指標與具日期的預測 |
| models/lstm_metrics.csv、lstm_predictions.csv | LSTM 指標與具日期的預測 |
| figures/models/forecast_<symbol>.png | 每股 actual 與所有已存模型預測對照 |
| analysis.rds、RUN_NOTES.txt | R 分析物件、假設與執行環境 |

歷史 Excel 與目前重訓是不同批次的證據。目前模型 CSV 的 predicted_period_return 使用小數，表示逐筆預測序列首末變化，並非期初可取得的全期投資報酬；也不能補稱為原簡報缺失的逐股 RMSE 排除依據。

檔案數量取決於執行模式與已有模型：

| 執行狀態 | 本次分析圖數 | 分析表 CSV 數 |
|---|---:|---:|
| 乾淨輸出、沒有模型的預設流程 | 16 | 15 |
| 已有完整 22 股三模型的預設流程 | 38 | 16 |
| 完整模型加 --all-pairs | 472 | 16 |

上述表格以 tseries 等依賴皆已安裝為前提。472 張圖為 **16 張核心圖＋434 張額外股票 CCF＋22 張預測比較圖**；核心圖已含一組股票及一組 ETF CCF，因此股票配對總數為 435。另有四份模型 CSV、完整執行稽核檔，以及報告的六張整合圖與四份 PDF，不計入這個分析圖表數。

較小的重跑不會清除先前的額外配對圖，因此「資料夾現存數」可能大於「本次重畫數」。

## 程式分工

| 檔案 | 負責內容 |
|---|---|
| [run.R](run.R) | 主入口、串接分析、驗證／載入結果及儲存 |
| [R/config.R](R/config.R) | 日期、股號名單、歷史權重、BL views 與共用參數 |
| [R/data.R](R/data.R) | 讀檔、日期對齊、報酬、統計、ADF 與選股 |
| [R/models.R](R/models.R) | 視窗、RF／XGBoost 訓練、模型輸出驗證及載入 |
| [R/portfolio.R](R/portfolio.R) | MV／BL、效率前緣、淨值與績效 |
| [R/plots.R](R/plots.R) | 共用 PNG／PDF 圖、CCF、復發及模型預測 |
| [scripts/install_packages.R](scripts/install_packages.R) | 明確執行的 R 套件安裝 |
| [scripts/train_lstm.py](scripts/train_lstm.py) | CPU LSTM、時間切分及 train-only scaling |
| [scripts/build_reports.py](scripts/build_reports.py) | 數值核對、彩色整合圖、中英文 PDF 與來源清冊 |
| [tests/run_tests.R](tests/run_tests.R) | R 計算、資料對齊、載入與實際模型檢查 |
| [tests/test_lstm.py](tests/test_lstm.py) | Python 視窗、日期、縮放與訓練檢查 |
| [PortfolioOptimization.Rproj](PortfolioOptimization.Rproj) | RStudio 專案設定 |

## 完整執行與驗證

**2026-10-21** 已完成原生 R／Python 全流程：**32 項 R 檢查＋8 項 Python 測試通過**，22 股三模型產生 **66 組指標與 15,477 筆測試預測**。日期、actual close、RMSE 與 MAE 均另行對照原始 Excel；472 張分析 PNG 皆通過解碼檢查。當次也重建並逐頁檢查了兩份 12 頁彩色報告。

R 主流程約 **102 秒**，LSTM 全 22 股訓練約 **148 秒**；不含首次安裝與版面檢查，亦不代表其他電腦的執行保證。

- [完整執行摘要與逐股比較](outputs/full_run/2026-10-21/RUN_SUMMARY.md)
- [R 主流程日誌](outputs/full_run/2026-10-21/r_full_pipeline.log)／[R 測試日誌](outputs/full_run/2026-10-21/r_tests.log)
- [LSTM 執行日誌](outputs/full_run/2026-10-21/lstm_full_run.log)
- [獨立核對紀錄](outputs/full_run/2026-10-21/verification.json)
- [專案驗證紀錄](docs/VALIDATION.md)／[報告驗證紀錄](reports/VALIDATION.md)

早期 WebR 的執行範圍保留在歷史驗證紀錄；原生完整重跑已補驗當時未能執行的模型路徑。完整執行證明程式可運作，上述研究限制仍然適用。

## 參考資料與封存

[references/](references/) 保留引用論文及 **37 張歷史圖稿**：30 張股票分解、4 張 ETF 分解、2 張復發圖、1 張 MV 前緣圖。其中 3711／2311 原復發圖因缺少 2311 原始行情而僅作歷史證據，不以其他股票冒名替代。

[archive/](archive/) 保留正式提交 RAR 的 12 份來源，以及 legacy ZIP 的 14 份相關舊程式／Notebook。日常執行使用根目錄入口，封存供比對與還原；舊工作階段、重複壓縮檔及無關附件已於整理時移除。

還原方式見 [封存說明](archive/README.md)，搬移及刪除理由見 [資料夾整理紀錄](docs/FOLDER_CLEANUP.md)，計算修正見 [重構紀錄](docs/REFACTOR_NOTES.md)。封存中的舊清冊路徑反映整理前結構，並非目前的檔案位置。
