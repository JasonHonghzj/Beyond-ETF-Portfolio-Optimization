# 中英文研究報告

繁體中文｜[English](README.md) · [返回專案說明](../README_zh.md)

本專題完成於 **Spring 2024（2024 年春季學期）巨量資料分析課程**，市場資料截止於 **2023-11-30**。**2026-10-21** 完成原生 R／Python 全流程重跑及三模型、22 股完整重訓，沒有延長市場資料期間。

| 版本 | PDF | 可編輯敘述來源 | 作者 |
|---|---|---|---|
| 繁體中文 | [report_zh.pdf](report_zh/report_zh.pdf) | [content.md](report_zh/content.md) | 蘇柏諺、洪稚鈞、佘梓平、黃纓婷、陳依琪、林岱融 |
| 英文 | [report_en.pdf](report_en/report_en.pdf) | [content.md](report_en/content.md) | Bo-Yan Su, Zhi-Jun Hong, Tzu-Ping She, Ying-Ting Huang, I-Chi Chen, Tai-Jung Lin |

報告採用 [OSDI 2024 投稿範本](https://www.usenix.org/conference/osdi24/requirements-authors)。

兩份報告採用相同的兩行標題版面，首頁依序列出作者、系所、指導教授、課程及研究學期。所屬單位為**國立成功大學統計學系**／**Department of Statistics, National Cheng Kung University, Taiwan.**；指導教授列為**指導教授：鄭順林**／**Advised by Prof. Shun-Lin Jeng**。課程與 **Spring 2024** 各自成行，使用一般字體。兩份報告均依上表順序列出六位組員，洪稚鈞位於第二位。

最後的參考文獻頁僅保留 **Min-Yuh Day 與 Jian-Ting Lin（2019）**的研究論文，統一編為 **[1]**。專題簡報、自行產生的圖表、程式產出及格式資源改由專案說明與來源清冊記錄，不列入報告的文獻書目。

| 中文姓名 | 英文姓名 |
|---|---|
| 蘇柏諺 | Bo-Yan Su |
| 洪稚鈞 | Zhi-Jun Hong |
| 佘梓平 | Tzu-Ping She |
| 黃纓婷 | Ying-Ting Huang |
| 陳依琪 | I-Chi Chen |
| 林岱融 | Tai-Jung Lin |

## 檔案與重建方式

`report_zh/` 與 `report_en/` 分別保存可編輯敘述來源及最終 PDF。`assets/` 內的六張整合圖由報告程式管理；本目錄的來源清冊與驗證檔記錄來源雜湊、數據核對與版面檢查。

在專案根目錄執行，使用 Python 3.10 或以上版本：

```powershell
python -m pip install -r scripts/requirements-reports.txt
python scripts/build_reports.py
```

字型預設讀取 `C:/Windows/Fonts`。其他系統可用 `--font-dir` 指向含 `times.ttf`、`timesbd.ttf`、`timesi.ttf`、`timesbi.ttf` 與 `mingliu.ttc` 的合法字型目錄。若 Matplotlib 預設快取位置不可寫，可將 `MPLCONFIGDIR` 指向可寫位置。

報告程式只讀取本地資料與既有 16 份分析 CSV，產生六張整合圖及中英文兩份 PDF；每份 12 頁，共 24 頁。建置過程不下載市場資料或重新訓練模型。資料、假設或結果改變時，須一併審查中英文敘述來源；程式會在產生 PDF 前核對主要數據主張。

完整分析包含 472 張 PNG：16 張核心圖、434 張額外股票配對 CCF 及 22 張三模型預測圖，目前產出保存在 `../outputs/`。重構前自行產生的 37 張圖另存於[歷史結果封存](../archive/historical-results/README_zh.md)，外部引用論文在 `../references/papers/`。

## 證據與驗證

- [report_manifest.json](report_manifest.json)：來源及產出 SHA-256、作者、版面設定、數據核對與研究限制。
- [validation.json](validation.json)：兩份共 24 頁的紙張尺寸、文字邊界、字型內嵌、頁碼及作者順序檢查；圖表另進行彩色與灰階視覺核對。
- [VALIDATION.md](VALIDATION.md)：逐頁視覺檢查與計算驗證範圍。
- [完整執行證據](../outputs/full_run/2026-10-21/)：原生 R 4.6.1 執行、32 項 R 檢查、八項 Python 測試，以及完整模型訓練的命令與結果。
- [原始簡報](../docs/presentation.pdf)與[來源資料](../data/)：與既有分析表一併使用的研究輸入。

歷史配置與重新估計的投組分開呈現。結果使用未調整收盤價，未納入配息再投入與成本，配置比較亦屬同期間樣本內評價。完整重訓涵蓋 22 股，設定為 RF 500 棵樹、XGBoost 10 rounds、LSTM 50 epochs，共產生 66 筆指標與 15,477 筆測試預測。預設 R 流程會保留並載入已存模型結果；目前重訓無法補回原研究缺失的逐股 RMSE 排除紀錄。
