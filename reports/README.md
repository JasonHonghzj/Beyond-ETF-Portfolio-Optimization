# 中英文研究報告 / Bilingual research reports

本專題完成於 **Spring 2024**；市場資料截止於 **2023-11-30**。2026-10-21 完成原生 R／Python 全流程重跑及三模型、22 股完整重訓，未加入新的市場期間。

The project was completed in **Spring 2024**, using data ending **2023-11-30**. Native R/Python execution and full retraining of three models across 22 stocks were completed on 2026-10-21 without extending the market-data period.

| 版本 / Version | PDF | 可編輯內容 / Editable narrative | 作者 / Authors |
|---|---|---|---|
| 繁體中文・署名課程版 | [report_zh.pdf](report_zh/report_zh.pdf) | [content.md](report_zh/content.md) | 蘇柏諺、洪稚鈞、佘梓平、黃纓婷、陳依琪、林岱融 |
| English・署名課程版 | [report_en.pdf](report_en/report_en.pdf) | [content.md](report_en/content.md) | Bo-Yan Su, Zhi-Jun Hong, Tzu-Ping She, Ying-Ting Huang, I-Chi Chen, Tai-Jung Lin |

報告採用 [OSDI 2024 template](https://www.usenix.org/conferences/author-resources/paper-templates)。

The reports use the [OSDI 2024 template](https://www.usenix.org/conferences/author-resources/paper-templates).

| 中文姓名 / Chinese name | 英文姓名 / English name |
|---|---|
| 蘇柏諺 | Bo-Yan Su |
| 洪稚鈞 | Zhi-Jun Hong |
| 佘梓平 | Tzu-Ping She |
| 黃纓婷 | Ying-Ting Huang |
| 陳依琪 | I-Chi Chen |
| 林岱融 | Tai-Jung Lin |

## 重建 / Rebuild

在專案根目錄執行，使用 Python 3.10 或以上版本：

Run from the project root with Python 3.10 or newer:

```powershell
python -m pip install -r scripts/requirements-reports.txt
python scripts/build_reports.py
```

預設讀取 Windows 的 `C:/Windows/Fonts`。其他系統可用 `--font-dir` 指向含 `times.ttf`、`timesbd.ttf`、`timesi.ttf`、`timesbi.ttf` 與 `mingliu.ttc` 的合法字型目錄。若 Matplotlib 預設快取位置不可寫，可將 `MPLCONFIGDIR` 指向可寫位置。

The default font directory is `C:/Windows/Fonts`. Use `--font-dir` to provide the listed licensed font files on another system. Set `MPLCONFIGDIR` to a writable directory if the default Matplotlib cache is unavailable.

報告產製程式只讀取本地資料與既有 16 份 CSV，重建 6 張整合圖及中英文兩份 PDF；每份報告 12 頁，共 24 頁。報告建置本身不下載市場資料或重新訓練模型。`assets/` 內的整合圖由此程式管理。若固定敘述與績效數據不再一致，程式會要求先審查內容。已完成的完整分析包含 472 張 PNG：16 張核心圖、434 張額外股票配對 CCF 及 22 張三模型預測圖。

The report generator reads local data and 16 existing CSV tables to produce six composite figures and two 12-page PDFs, totaling 24 pages. Report construction itself does not download market data or retrain models. The completed analysis has 472 PNGs: 16 core figures, 434 additional stock-pair CCFs, and 22 three-model forecast panels. Review both narrative sources whenever results change.

## 證據與驗證 / Evidence and verification

- [report_manifest.json](report_manifest.json)：來源及產出 SHA-256、作者、版面、數據核對與研究限制。
- [validation.json](validation.json)：兩份共 24 頁的紙張尺寸、文字邊界、字型內嵌、頁碼及作者順序檢查；圖表另完成彩色與灰階視覺核對。
- [VALIDATION.md](VALIDATION.md)：逐頁視覺檢查與計算驗證範圍。
- [完整執行證據](../outputs/full_run/2026-10-21/)：原生 R 4.6.1 執行與 32 項檢查、Python 八項測試、LSTM 22 股 × 50 epochs 設定及結果。RF 使用 500 棵樹，XGBoost 使用 10 rounds；合併輸出含 66 筆指標、15,477 筆測試預測。
- 原始資料、簡報、16 份 CSV、472 張分析 PNG 及 37 張歷史圖稿保留於專案正式路徑。預設不重訓入口會保留已存的三模型結果。

Historical allocations and refitted portfolios are reported separately. Results use unadjusted closing prices without reinvested distributions or costs, and the allocation comparison is in-sample. Full retraining completed for RF (500 trees), XGBoost (10 rounds), and LSTM (50 epochs) across 22 stocks, producing 66 metric rows and 15,477 test predictions. Native R checks and Python tests passed; execution evidence is in [outputs/full_run/2026-10-21/](../outputs/full_run/2026-10-21/). Current retraining does not recover the missing historical RMSE exclusion records.
