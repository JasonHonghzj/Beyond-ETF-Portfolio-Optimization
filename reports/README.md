# Bilingual research reports

English | [繁體中文](README_zh.md) · [Back to the project guide](../README.md)

This **Spring 2024** Big Data Analytics final project uses market data ending **November 30, 2023**. The native R/Python pipeline and full retraining of three models across 22 stocks were completed on **October 21, 2026**, without extending the market-data period.

| Report | PDF | Editable narrative | Authors |
|---|---|---|---|
| Traditional Chinese | [report_zh.pdf](report_zh/report_zh.pdf) | [content.md](report_zh/content.md) | 蘇柏諺、洪稚鈞、佘梓平、黃纓婷、陳依琪、林岱融 |
| English | [report_en.pdf](report_en/report_en.pdf) | [content.md](report_en/content.md) | Bo-Yan Su, Zhi-Jun Hong, Tzu-Ping She, Ying-Ting Huang, I-Chi Chen, Tai-Jung Lin |

The reports use the [OSDI 2024 submission template](https://www.usenix.org/conference/osdi24/requirements-authors).

The affiliation appears below the author names: **國立成功大學統計學系** in Chinese and **Department of Statistics, National Cheng Kung University, Taiwan.** in English. Both reports list all six members in the order shown above, with Zhi-Jun Hong second.

| Chinese name | English name |
|---|---|
| 蘇柏諺 | Bo-Yan Su |
| 洪稚鈞 | Zhi-Jun Hong |
| 佘梓平 | Tzu-Ping She |
| 黃纓婷 | Ying-Ting Huang |
| 陳依琪 | I-Chi Chen |
| 林岱融 | Tai-Jung Lin |

## Files and rebuild

`report_zh/` and `report_en/` contain the editable narrative sources and final PDFs. `assets/` contains six composite figures managed by the report builder. The manifest and validation files in this directory record source hashes, numerical checks, and layout checks.

Run from the project root with Python 3.10 or newer:

```powershell
python -m pip install -r scripts/requirements-reports.txt
python scripts/build_reports.py
```

The default font directory is `C:/Windows/Fonts`. On another system, use `--font-dir` to provide a licensed font directory containing `times.ttf`, `timesbd.ttf`, `timesi.ttf`, `timesbi.ttf`, and `mingliu.ttc`. Set `MPLCONFIGDIR` to a writable directory if the default Matplotlib cache is unavailable.

The report generator reads local data and 16 saved analysis CSVs to produce six composite figures and two 12-page PDFs, totaling 24 pages. It does not download market data or retrain models. Review both narrative sources whenever data, assumptions, or results change; the builder checks key numerical claims before producing the PDFs.

The completed analysis contains 472 PNGs: 16 core figures, 434 additional stock-pair CCFs, and 22 three-model forecast panels. These current outputs are in `../outputs/`. The 37 earlier project-generated figures are kept separately in the [historical-results archive](../archive/historical-results/README.md), and external cited papers are in `../references/papers/`.

## Evidence and verification

- [report_manifest.json](report_manifest.json): source and output SHA-256 hashes, authors, layout settings, numerical checks, and research limitations.
- [validation.json](validation.json): paper dimensions, text boundaries, embedded fonts, page numbers, and author order for both reports, totaling 24 pages. Figures also receive color and grayscale visual checks.
- [VALIDATION.md](VALIDATION.md): the scope of page-by-page visual inspection and calculation checks.
- [Full-run evidence](../outputs/full_run/2026-10-21/): native R 4.6.1 execution, 32 R checks, eight Python tests, and the commands and results of full model training.
- [Original presentation](../docs/presentation.pdf) and [source data](../data/): the project inputs used alongside the saved analysis tables.

Historical allocations and refitted portfolios are reported separately. Results use unadjusted closing prices without reinvested distributions or costs, and the allocation comparison is in-sample. Full retraining completed for RF (500 trees), XGBoost (10 rounds), and LSTM (50 epochs) across 22 stocks, producing 66 metric rows and 15,477 test predictions. The default R workflow preserves and loads these saved model results. Current retraining does not recover the missing historical RMSE exclusion records.
