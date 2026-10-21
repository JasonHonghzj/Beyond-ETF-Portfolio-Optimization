# 驗證紀錄

## 2026-10-21：原生環境完整執行

本次已在 Windows 的原生 R 與 Python 環境完整執行整理後的程式。完成狀態以 [R 執行記錄](../outputs/full_run/2026-10-21/r_execution.json) 為準：`r_tests` 與 `r_full_pipeline` 均為 `exit_code: 0`。R 主流程包含 `--train --all-pairs`；LSTM 另外完成全部 22 股訓練後，由 R 載入並整合輸出。

| 項目 | 結果 |
|---|---|
| R 回歸檢查 | 32 項全部通過，包含模型套件的實際訓練檢查 |
| Python LSTM unittest | 8 項全部通過，涵蓋視窗／日期、train-only scaling、seed 重現、常數／錯誤資料、輸出 schema |
| 原始資料與主流程 | 全部 30 股、10 ETF 成功讀取，產生分析物件、假設紀錄、全部圖表與績效表 |
| RF 完整訓練 | 22 股，每股 500 trees |
| XGBoost 完整訓練 | 22 股，每股 10 rounds |
| LSTM 完整訓練 | 22 股，每股 50 epochs；CPU、單執行緒、seed 1、deterministic algorithms |
| 模型整合 | 66 份模型指標、15,477 筆預測；每種模型各 5,159 筆 |
| 預測資料對齊 | 每種模型中，20 股各有 235 筆、2603 有 234 筆、6669 有 225 筆；三種模型全部日期、actual close 與指標均已獨立核對原始 Excel |
| 分析表格 | `outputs/tables/` 共 16 份 CSV，包含整合後的 `combined_forecast_metrics.csv` |
| 分析圖表 | `outputs/figures/` 共 472 張 PNG，包含 435 組個股 CCF、1 組 ETF CCF、22 張模型預測圖 |
| 原有分析表格比較 | 核心結果在浮點精度內相同；15 份原有 CSV 中，14 份正規化換行後一致，相關矩陣的最大數值差約 9.72×10⁻¹⁷ |
| 執行結束碼與耗時 | R 測試結束碼 0，約 1.568 秒；R 完整流程結束碼 0，約 102.056 秒；LSTM 完整訓練約 147.620 秒 |

詳細指令、執行順序、產物清冊與本次本機 `Rscript` 路徑見 [完整執行摘要](../outputs/full_run/2026-10-21/RUN_SUMMARY.md)。本次原生 R runtime 放在工作暫存區；它不是專案的相依套件或可攜式執行入口。日後重現請安裝 R 與套件，並確認終端機可使用 `Rscript`。

### 執行環境

| 項目 | 版本 |
|---|---|
| R | 4.6.1，Windows 原生執行 |
| readxl | 1.6.0 |
| quadprog | 1.5-8 |
| igraph | 2.3.4 |
| tseries | 0.10-63 |
| randomForest | 4.7-1.2 |
| xgboost | 3.2.1.1 |
| Python | 3.10.10 |
| NumPy／pandas | 1.23.5／2.1.3 |
| PyTorch | 2.0.1 CPU |
| openpyxl | 3.1.5，本次由 bundled runtime 提供 |

完整 R `sessionInfo()` 保留於 [RUN_NOTES.txt](../outputs/RUN_NOTES.txt)。Python 正式使用時請依 `scripts/requirements-lstm.txt` 安裝相依套件。

### 可檢查的執行記錄

- [R 測試日誌](../outputs/full_run/2026-10-21/r_tests.log)
- [R 完整流程日誌](../outputs/full_run/2026-10-21/r_full_pipeline.log)
- [R 結束碼、指令與耗時](../outputs/full_run/2026-10-21/r_execution.json)
- [LSTM 完整訓練日誌](../outputs/full_run/2026-10-21/lstm_full_run.log)
- [LSTM 指標、原始資料對齊與 SHA-256 驗證](../outputs/full_run/2026-10-21/lstm_full_run_validation.json)
- [三種模型、產物清冊與原有表格的獨立驗證](../outputs/full_run/2026-10-21/verification.json)

### 重現完整流程

```powershell
Rscript --vanilla scripts/install_packages.R --diagnostics --models
python -m pip install -r scripts/requirements-lstm.txt

Rscript --vanilla tests/run_tests.R --models
python -B -m unittest discover -s tests -p test_lstm.py -v
python scripts/train_lstm.py
Rscript --vanilla run.R --train --all-pairs
```

LSTM 先產生預測檔，再由 R 完整流程一併載入，可同時得到三種模型的合併表與 22 張預測圖。上述是重現完整執行的順序；預設 `Rscript --vanilla run.R` 仍使用已儲存的模型結果，並僅重畫代表性 CCF。

### 仍適用的研究限制

完整執行證明目前程式與資料可以跑完，並未改變分析的研究範圍：

- 原始研究為 Spring 2024，資料仍截至 2023-11-30，沒有加入 2026 年市場資料。
- 重新估計的投資組合在同一個 2023 年視窗擬合與評估，屬於樣本內診斷；不能解讀為樣本外投資回測。
- 資料為本機收盤價，未納入配息再投入、交易成本、稅費與公司行動調整。
- ML 預測使用已觀察到的前 20 筆收盤價；預測路徑首末差不是測試期初即可取得的可交易報酬。
- 本次 66 份指標是目前重構程式的重訓結果，沒有補回原始簡報缺失的逐股完整 RMSE 表；不能用它們宣稱精確重現原先選股時的誤差排名。
- BL 設定採等權 prior、樣本共變異數及指定年度 views／Omega，與原 notebook 的 Yahoo、市值、Ledoit–Wolf、L2 流程不同。
- 原始 `3711/2311` 復發圖因缺少 2311 原始資料，仍無法重新生成；未以其他股票替代。

## 2026-10-20：整理階段的歷史驗證

以下保留當時的執行範圍。當時使用 WebR、尚未完成原生 XGBoost 與全 22 股重訓的限制，已由 2026-10-21 的原生完整執行補驗。

### 當時已通過

| 項目 | 結果 |
|---|---|
| R 原始碼解析、主入口與參數說明 | 通過，清理後重新執行 |
| R 回歸檢查 | 31 項通過：日期對齊、20 筆視窗、時間切分、權重與價格尺度、複利、回撤、年化風險、解析切點、BL views、選股、既存預測驗證、復發矩陣 |
| Python LSTM unittest | 8 項通過：視窗／日期、train-only scaling、seed 重現、常數／錯誤資料、輸出 schema |
| 實際專案主流程 | 全部 30 股、10 ETF 成功讀取；產生 16 張 PNG、15 份 CSV、analysis.rds 與 RUN_NOTES.txt |
| ADF、相關性與選股 | 已實際計算；選股與原簡報差異另表輸出 |
| RF 實際訓練 | 2330，500 trees、940/235 切分，235 個有限預測，RMSE 約 9.9145 |
| LSTM 實際訓練 | 2330，50 epochs、940/235 切分，RMSE 約 15.1320、MAE 約 12.9488 |
| 模型輸出整合 | 實際 RF 與另訓練的 LSTM CSV 可在預設重跑時一併保留，470 筆預測、2 份指標，並成功產生共同預測圖 |
| 圖表檢查 | 已目視實際累積報酬、配置、前緣、比較與復發圖；修正圖例裁切，13 個系列完整顯示 |
| 其他圖表邊界 | 合成資料涵蓋負報酬、負 Sharpe、零波動／N/A、單模型與多模型預測、PNG／PDF 裝置 |
| 第一階段備份（歷史紀錄） | 原 ZIP 的 21 個檔案內容與 SHA-256 一致，移除前再次逐檔比對；第二階段改為只保留 14 份來源的 legacy-source.zip |
| 第一階段原始輸入（歷史紀錄） | 當時 89 個資料／附件的 SHA-256 全數一致，見 archive/cleanup-verification.json；後續刪除與移動以 FOLDER_CLEANUP.json 為準 |

當時的實際訓練檢查產物放在工作暫存區；`outputs/models/` 沒有混入只訓練一支股票的測試結果。當時的 16 張圖與 15 份表是完整預設歷史重建流程的結果。

第二階段資料夾分類後，再次通過 31 項 R 檢查、8 項 Python 測試及完整主流程；新 `data/stocks/` 路徑的 LSTM CLI 也以 2330、2 epochs 實測成功。81 個搬移檔案的 SHA-256 全部一致，重跑所得 15 份 CSV 與搬移前逐位元一致。十四份來源 ZIP 可解壓且雜湊通過，詳見 `FOLDER_CLEANUP.json`。

### 當時的執行環境與限制

當時本機沒有原生 `Rscript`，因此用暫存的 WebR 0.6.0／R 4.6.0 實際執行 R 程式。其 `/project` 掛載對應本專案資料夾，當時 `analysis.rds`／RUN_NOTES 的路徑與 sessionInfo 反映該驗證環境；這些產物已於 2026-10-21 原生重跑時更新。驗證 runtime 及下載套件未加入專案。

主要已載入套件：readxl 1.5.0.1、quadprog 1.5-8、igraph 2.3.1、tseries 0.10-63。Python 為 3.10.10，NumPy 1.23.5、pandas 2.1.3、PyTorch 2.0.1 CPU；讀取 Excel 時暫借 bundled runtime 的 openpyxl。正式使用請依 requirements 安裝。

**2026-10-20 當時尚未通過原生 R 的 XGBoost 重訓驗證。** WebR 的 XGBoost 二進位套件載入時出現 WebAssembly shared-memory 不相容，因此當時沒有宣稱 `--train` 的 RF＋XGB 完整流程已跑完。R 的 XGB 程式已解析，並使用共用、已測試的 20 筆 lag 資料及標準 xgb.DMatrix／xgb.train API；當時記錄的後續驗證指令如下，現已在 2026-10-21 完成：

```powershell
Rscript --vanilla scripts/install_packages.R --models
Rscript --vanilla tests/run_tests.R --models
Rscript --vanilla run.R --train
```

2026-10-20 當時未做三種模型全 22 股的完整重訓，也未生成全部 435 組個股 CCF；兩項均已在 2026-10-21 的原生完整執行完成。預設執行仍不會重訓模型或產生全部配對圖。
