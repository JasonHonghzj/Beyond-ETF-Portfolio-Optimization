# Source-code and historical-results archive

English | [繁體中文](README_zh.md) · [Back to the project guide](../README.md)

This directory preserves the earlier source code, generated figures, and organization records of the Spring 2024 project. Use the root `run.R` and maintained scripts for current analysis.

| File or directory | Contents and purpose |
|---|---|
| `final-submission-source.rar` | The original `Final project/BDA_Final_Project_Team3_code.rar`, containing 12 submitted R/notebook source files, including LSTM and BL |
| `legacy-source.zip` | 14 relevant earlier sources: 11 R scripts, two Python scripts, and one notebook, retained for comparison and recovery |
| `legacy-source-manifest.json` | Retained members of the current legacy ZIP and their verification records |
| `original-manifest.json` | The first code-cleanup inventory and SHA-256 hashes; paths reflect the earlier folder structure |
| `cleanup-verification.json` | Verification from the first code cleanup, recording the then-current 21 backups and 89 original inputs |
| [historical-results/](historical-results/) | 37 figures generated before refactoring, with an inventory and SHA-256 manifest |

`legacy-source.zip` was reorganized from `original-code-20261020.zip`. It retains the relevant R, BL Python, and notebook sources, including the unique exported Python source `Untitled1 (2).py` recovered from a nested ZIP. Six `.RData`/`.Rhistory` session files and two nested notebook ZIPs were removed. These session and classroom records are not included in the current archive.

The earlier sources retain their original hardcoded paths and experimental settings. To inspect them, first extract them into a separate directory:

```powershell
Expand-Archive -LiteralPath archive/legacy-source.zip -DestinationPath archive/restored-legacy-source
```

Run this command from the project root. Current research inputs are in `data/stocks/`, `data/etfs/`, and `data/historical/`; the presentation is `docs/presentation.pdf`. External cited papers belong in `references/papers/`, current analysis outputs in `outputs/`, and reports and composite figures in `reports/`.

The 37 project-generated figures were moved from `references/figures/` to [historical-results/figures/](historical-results/figures/): 30 stock decomposition plots, four ETF decomposition plots, two recurrence plots, and one MV frontier image. They preserve the project's earlier execution results. The [figure guide](historical-results/README.md) and [figure_manifest.json](historical-results/figure_manifest.json) record categories, current paths, and file hashes. See the [folder-cleanup record](../docs/FOLDER_CLEANUP.md) for moves and deletions.

`original-manifest.json` and `cleanup-verification.json` preserve evidence of the first cleanup. Their old paths and file counts do not describe the current inventory or imply that removed files can still be recovered. Refer to `legacy-source-manifest.json` for the current legacy source archive.
