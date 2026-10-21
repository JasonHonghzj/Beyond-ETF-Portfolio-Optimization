# 專題原始碼封存

| 檔案 | 內容與用途 |
|---|---|
| `final-submission-source.rar` | 原 `Final project/BDA_Final_Project_Team3_code.rar`，保留正式提交的 12 份 R／Notebook 原始碼，包括 LSTM 與 BL |
| `legacy-source.zip` | 保留 14 份相關舊來源：11 支 R、2 支 Python、1 份 Notebook，供比對與還原 |
| `legacy-source-manifest.json` | 目前 `legacy-source.zip` 的保留成員與驗證紀錄 |
| `original-manifest.json` | 第一次程式整理時的原始檔案清冊及 SHA-256，路徑反映整理前結構 |
| `cleanup-verification.json` | 第一次程式整理時的驗證結果，反映當時 21 份備份與 89 份原始輸入的狀態 |

`legacy-source.zip` 由原 `original-code-20261020.zip` 整理而來，保留相關 R、BL Python 與 Notebook，並從原巢狀 ZIP 取出唯一的 Python 匯出來源 `Untitled1 (2).py`。三組 `.RData`／`.Rhistory` 共六個工作階段檔，以及兩份巢狀 Notebook ZIP 已移除；目前封存不包含這些工作階段或課堂紀錄。

舊來源內的硬編碼路徑與實驗設定仍保留原樣。日常執行使用專案根目錄的 `run.R`；如需檢查舊程式，先解壓到獨立資料夾：

```powershell
Expand-Archive -LiteralPath archive/legacy-source.zip -DestinationPath archive/restored-legacy-source
```

正式資料已集中於 `data/stocks/`、`data/etfs/` 與 `data/historical/`；正式簡報在 `docs/presentation.pdf`，論文及原始圖稿在 `references/`。搬移與刪除依據見 [全資料夾整理紀錄](../docs/FOLDER_CLEANUP.md)。

`original-manifest.json` 與 `cleanup-verification.json` 保留第一次整理的歷史證據，不能用其舊路徑或檔案數認定目前檔案缺漏，也不代表已刪除的前期資料仍可從目前封存還原。現有舊來源以 `legacy-source-manifest.json` 為準。
