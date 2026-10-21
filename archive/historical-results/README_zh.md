# 歷史分析結果封存

[English](README.md) | 繁體中文 | [專案說明](../../README_zh.md)

這 37 張圖是程式與目錄整理前，由本專案早期分析產生的結果。因此封存於此，不再歸類為外部參考資料；引用論文仍保留在 [references/papers/](../../references/papers/)。

| 位置 | 檔案數 | 內容 |
|---|---:|---|
| [figures/decomposition/stocks/](figures/decomposition/stocks/) | 30 | 原始股票分解圖 |
| [figures/decomposition/etfs/](figures/decomposition/etfs/) | 4 | 原始 ETF 分解圖 |
| [figures/recurrence/](figures/recurrence/) | 2 | 原始復發圖 |
| [figures/portfolio/](figures/portfolio/) | 1 | 原始六股 MV 效率前緣 |

分解圖保留 trend、seasonal 與 remainder 面板，與目前程式的趨勢圖不同。3711／2311 的歷史復發圖因缺少 2311 原始行情，無法依現有資料重建；原始 MV 前緣則記錄早期計算，應與目前重新估計的前緣分開解讀。

[figure_manifest.json](figure_manifest.json) 記錄各檔案最初路徑、前次 `references/figures/` 位置、現址、檔案大小與 SHA-256。37 張圖搬移時未更動內容，並與[原始清理紀錄](../../docs/FOLDER_CLEANUP.json)逐一核對。

新分析產出放在 [outputs/](../../outputs/)，報告整合圖放在 [reports/assets/](../../reports/assets/)。目前流程不會覆寫此封存。這些歷史圖與目前 472 張分析 PNG、六張報告整合圖分別計數。
