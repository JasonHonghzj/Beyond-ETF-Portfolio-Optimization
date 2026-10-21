# 完整執行結果：2026-10-21

**全部主要流程已實際執行成功**，使用專案正式設定，未縮短 epochs、RF 樹數或股票名單。研究仍為 Spring 2024，市場資料截止於 2023-11-30；此次日期僅代表程式執行及驗證。

| 步驟 | 實際結果 |
|---|---|
| 原生 R 與套件 | R 4.6.1 Windows；專案 install_packages.R --all 通過 |
| R 回歸測試 | 32 項通過，包含 RF/XGBoost 真實資料訓練測試 |
| Python 測試 | 8 項通過 |
| 資料讀取 | 30 檔股票、10 檔 ETF，共 40 份價格 Excel |
| RF | 22 股，每股 500 trees，5,159 筆測試預測 |
| XGBoost | 22 股，每股 10 rounds，5,159 筆測試預測 |
| LSTM | 22 股，每股 50 epochs，5,159 筆測試預測 |
| 模型指標 | 66 組（22 股 × 3 模型），無缺漏、無重複 |
| 預測明細 | 15,477 筆，日期及 actual close 逐筆對照原始 Excel；RMSE／MAE 另行重算一致 |
| 分析資料表 | 16 份 CSV，包含合併模型指標 |
| 分析圖片 | 472 張 PNG，全部檔案解碼檢查通過 |
| CCF | 全 435 組股票配對，另加 1 組 ETF，共 436 張 |
| 模型比較圖 | 22 張，各含 actual、RF、XGB、LSTM |
| 中英文報告 | 各 12 頁，彩色圖；更新本次完整重訓與來源清冊，24 頁版面／字型／作者檢查通過 |

R 主流程耗時 **102.056 秒**；LSTM 訓練耗時 **147.620 秒**。這兩項耗時不含首次環境下載安裝與報告排版檢查。

## 執行紀錄與原始輸出

- [R 完整主流程日誌](r_full_pipeline.log)、[R 測試日誌](r_tests.log)、[命令／時間／exit code](r_execution.json)
- [LSTM 測試與 22 股訓練日誌](lstm_full_run.log)、[LSTM 驗證明細](lstm_full_run_validation.json)
- [套件檢查](package_check.log)、[原生套件版本](native-package-versions.csv)、[執行環境](RUNTIME_SETUP.md)
- [全流程獨立核對](verification.json)、[22 股模型比較 CSV](model_comparison.csv)
- [66 組完整指標](../../tables/combined_forecast_metrics.csv)
- [RF／XGB 預測明細](../../models/forecast_predictions.csv)、[LSTM 預測明細](../../models/lstm_predictions.csv)
- [中文報告](../../../reports/report_zh/report_zh.pdf)、[英文報告](../../../reports/report_en/report_en.pdf)

## 各股測試 RMSE

同一股三模型使用相同測試日期，可比較各自誤差。不同股票的價格尺度不同，不宜直接把原始 RMSE 跨股平均來判定模型優劣。本次各股最低 RMSE 的模型數量為 RF 13 股、LSTM 6 股、XGBoost 3 股；這只是此次測試窗口的描述。

| 股票與預測圖 | RF RMSE | XGBoost RMSE | LSTM RMSE | 最低 RMSE | 測試筆數 |
|---|---:|---:|---:|---|---:|
| [2317](../../figures/models/forecast_2317.png) | 1.8389 | 2.2780 | 2.0803 | RF | 235 |
| [2330](../../figures/models/forecast_2330.png) | 9.9145 | 10.2377 | 15.1320 | RF | 235 |
| [2395](../../figures/models/forecast_2395.png) | 8.4923 | 10.1363 | 8.6557 | RF | 235 |
| [2357](../../figures/models/forecast_2357.png) | 9.1435 | 9.9668 | 14.5636 | RF | 235 |
| [3231](../../figures/models/forecast_3231.png) | 53.2110 | 54.9035 | 49.4001 | LSTM | 235 |
| [2207](../../figures/models/forecast_2207.png) | 47.2599 | 48.1724 | 25.9714 | LSTM | 235 |
| [2603](../../figures/models/forecast_2603.png) | 7.1960 | 8.6491 | 9.3344 | RF | 234 |
| [3034](../../figures/models/forecast_3034.png) | 9.3576 | 9.8383 | 16.3083 | RF | 235 |
| [3045](../../figures/models/forecast_3045.png) | 0.9820 | 0.9327 | 1.1274 | XGB | 235 |
| [2002](../../figures/models/forecast_2002.png) | 0.8530 | 1.0842 | 0.5713 | LSTM | 235 |
| [6669](../../figures/models/forecast_6669.png) | 432.3129 | 470.1705 | 294.0466 | LSTM | 225 |
| [1216](../../figures/models/forecast_1216.png) | 0.8079 | 0.8130 | 0.8168 | RF | 235 |
| [2303](../../figures/models/forecast_2303.png) | 1.0487 | 1.0966 | 1.3196 | RF | 235 |
| [3711](../../figures/models/forecast_3711.png) | 2.5094 | 3.0968 | 3.3401 | RF | 235 |
| [2308](../../figures/models/forecast_2308.png) | 26.4756 | 37.1170 | 20.9431 | LSTM | 235 |
| [2412](../../figures/models/forecast_2412.png) | 1.0538 | 1.0292 | 1.1145 | XGB | 235 |
| [2382](../../figures/models/forecast_2382.png) | 86.4081 | 88.4382 | 72.4086 | LSTM | 235 |
| [2454](../../figures/models/forecast_2454.png) | 23.0954 | 20.7690 | 26.2079 | XGB | 235 |
| [2881](../../figures/models/forecast_2881.png) | 0.9537 | 1.0003 | 1.2072 | RF | 235 |
| [2885](../../figures/models/forecast_2885.png) | 0.4121 | 0.4720 | 0.4363 | RF | 235 |
| [2886](../../figures/models/forecast_2886.png) | 0.4941 | 0.5216 | 0.6328 | RF | 235 |
| [6505](../../figures/models/forecast_6505.png) | 1.1003 | 1.2490 | 1.6443 | RF | 235 |

## 與先前結果的核對

原生 Windows R 寫出 CRLF 換行，因此 CSV 的檔案雜湊與先前 WebR 的 LF 檔案不同。正規化換行後，核心 15 表中 14 表內容完全一致；相關矩陣的最大數值差異為 **9.72 × 10⁻¹⁷**，屬浮點精度範圍。原始資料沒有更換，歷史 MV／BL／1/N 期間價格報酬仍約為 **40.40%／38.71%／39.57%**。

## 重現執行順序

準備 R 所需套件與兩份 Python requirements 後，在專案根目錄依序執行：

```powershell
Rscript --vanilla scripts/install_packages.R --all
Rscript --vanilla tests/run_tests.R --models
python -B -m unittest discover -s tests -p test_lstm.py -v
python scripts/train_lstm.py
Rscript --vanilla run.R --train --all-pairs
python scripts/build_reports.py
```

本次原生 R 安裝於獨立暫存目錄，未加入全域 PATH；本機的完整 Rscript 路徑及 R_LIBS_USER 設定見上方執行環境文件。Python 本次使用既有 PyTorch 與 bundled runtime 的 openpyxl／ReportLab，未更動模型程式或正式訓練設定。

## 解讀範圍

完整執行成功證明流程及輸出可運作，不等於預測模型具有穩定投資優勢。逐筆預測採時間切分，但選股與資產配置仍有歷史選擇及樣本內估計；資料是未調整收盤價，不含配息再投入、成本及稅費。2026 年重訓結果也不能替代缺失的 Spring 2024 歷史逐股 RMSE 表。
