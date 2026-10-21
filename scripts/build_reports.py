"""Build the bilingual, OSDI-2024-style course reports from checked local outputs.

Install requirements-reports.txt, then run: python scripts/build_reports.py
The Markdown files are the editable narrative source. This program supplies the
tables, color figures, page composition, provenance, and two final PDFs:
Chinese and English author-named reports.
No market download or model training is performed.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.dates as mdates
import matplotlib.font_manager as fm
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter
import numpy as np
import pandas as pd
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Frame, Paragraph, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
PAGE_W, PAGE_H = 612.0, 792.0
LEFT, BOTTOM, WIDTH, HEIGHT = 54.0, 72.0, 504.0, 648.0
GAP = 23.76
COL = (WIDTH - GAP) / 2
TOP = BOTTOM + HEIGHT
TERM = "Spring 2024"
REVIEW_DATE = "2026-10-21"
FINAL = ["3034", "2357", "2454", "2886", "3711", "2330"]
SCREENED = ["2317", "2330", "2395", "2357", "3231", "2207", "2603", "3034",
            "3045", "2002", "6669", "1216", "2303", "3711", "2308", "2412",
            "2382", "2454", "2881", "2885", "2886", "6505"]
AUTHORS_ZH = ["蘇柏諺", "洪稚鈞", "佘梓平", "黃纓婷", "陳依琪", "林岱融"]
# User-provided English names, with given names before surnames.
AUTHORS_EN = ["Bo-Yan Su", "Zhi-Jun Hong", "Tzu-Ping She", "Ying-Ting Huang", "I-Chi Chen", "Tai-Jung Lin"]
AFFILIATIONS = {
    "zh": "國立成功大學統計學系",
    "en": "Department of Statistics, National Cheng Kung University, Taiwan.",
}
HISTORICAL_FIGURES = Path("archive/historical-results/figures")
RULES = "https://www.usenix.org/conference/osdi24/requirements-authors"
TEMPLATE = "https://www.usenix.org/conferences/author-resources/paper-templates"
# Keep colors consistent across related panels, with line styles and markers
# providing a second visual cue for print and color-vision differences.
COLORS = {"MV": "#0072B2", "BL": "#D55E00", "1/N": "#009E73", "ETF": "#CC79A7"}
STOCK_COLORS = dict(zip(FINAL, ["#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9"]))
MODEL_COLORS = {"xgboost": "#0072B2", "RF": "#D55E00", "LSTM": "#009E73"}
CORE_TABLES = {
    "adf_tests.csv", "bl_annual_returns.csv", "bl_frontier.csv",
    "etf_descriptive_statistics.csv", "historical_ml_returns_percent.csv",
    "mv_frontier.csv", "presentation_buy_and_hold_wealth.csv",
    "presentation_price_performance.csv", "presentation_weights_normalized.csv",
    "recomputed_in_sample_performance.csv", "recomputed_in_sample_wealth.csv",
    "recomputed_in_sample_weights.csv", "stock_descriptive_statistics.csv",
    "stock_return_correlations.csv", "stock_selection_comparison.csv",
}


def load_forecast_validation(root: Path, tables: dict, raw: dict) -> dict | None:
    """Validate complete retraining evidence before describing it as complete.

    A historical-only reconstruction remains supported when no forecast files
    exist. Once model output is present, require both trainers and the matching
    combined table; partial or stale training must not become report evidence.
    """
    paths = {name: root / "outputs/models" / f"{name}.csv" for name in (
        "forecast_metrics", "forecast_predictions", "lstm_metrics", "lstm_predictions")}
    combined = tables.get("combined_forecast_metrics.csv")
    if combined is None and not any(path.exists() for path in paths.values()):
        return None
    if combined is None or not all(path.is_file() for path in paths.values()):
        raise ValueError("Complete RF/XGB/LSTM outputs and combined_forecast_metrics.csv are required together.")
    frames = {name: pd.read_csv(path, dtype={"symbol": str}) for name, path in paths.items()}
    metrics = pd.concat([frames["forecast_metrics"], frames["lstm_metrics"]], ignore_index=True)
    predictions = pd.concat([frames["forecast_predictions"], frames["lstm_predictions"]], ignore_index=True)
    metric_columns = ["symbol", "model", "rmse", "mae", "predicted_period_return",
                      "test_start", "test_end", "train_n", "test_n"]
    prediction_columns = ["date", "symbol", "model", "actual", "predicted"]
    if not set(metric_columns).issubset(metrics) or not set(metric_columns).issubset(combined):
        raise ValueError("Invalid model metric schema.")
    if not set(prediction_columns).issubset(predictions):
        raise ValueError("Invalid model prediction schema.")
    expected = {(symbol, model) for symbol in SCREENED for model in ("RF", "XGB", "LSTM")}
    for name, frame in (("trainer metrics", metrics), ("combined metrics", combined)):
        if len(frame) != len(expected) or frame[["symbol", "model"]].duplicated().any() or set(
                frame[["symbol", "model"]].itertuples(index=False, name=None)) != expected:
            raise ValueError(f"{name} must contain each of the 22 stocks and three models exactly once.")
        if frame[metric_columns].isna().any().any() or not np.isfinite(
                frame[["rmse", "mae", "predicted_period_return", "train_n", "test_n"]].to_numpy(dtype=float)).all():
            raise ValueError(f"Non-finite or missing values in {name}.")
    left = metrics[metric_columns].sort_values(["symbol", "model"]).reset_index(drop=True)
    right = combined[metric_columns].sort_values(["symbol", "model"]).reset_index(drop=True)
    for column in ("symbol", "model", "test_start", "test_end"):
        if not left[column].astype(str).equals(right[column].astype(str)):
            raise ValueError("Combined metrics do not match the saved trainer outputs.")
    numeric = ["rmse", "mae", "predicted_period_return", "train_n", "test_n"]
    if not np.allclose(left[numeric].to_numpy(float), right[numeric].to_numpy(float), rtol=0, atol=1e-6):
        raise ValueError("Combined metric values do not match the saved trainer outputs.")
    if predictions[prediction_columns].isna().any().any() or predictions[
            ["date", "symbol", "model"]].duplicated().any() or not np.isfinite(
            predictions[["actual", "predicted"]].to_numpy(dtype=float)).all():
        raise ValueError("Invalid, duplicated, or non-finite model predictions.")
    predictions["date"] = pd.to_datetime(predictions["date"], errors="raise")
    expected_count = 0
    maximum_metric_error = 0.0
    for metric in metrics.itertuples(index=False):
        prices = raw[metric.symbol].sort_index()
        train_n = int(np.floor((len(prices) - 20) * .8))
        actual = prices.iloc[20 + train_n:]
        rows = predictions[(predictions.symbol == metric.symbol) &
                           (predictions.model == metric.model)].sort_values("date")
        if (len(rows) != len(actual) or not np.array_equal(rows.date.to_numpy(), actual.index.to_numpy()) or
                not np.allclose(rows.actual.to_numpy(), actual.to_numpy(), rtol=0, atol=1e-7) or
                metric.train_n != train_n or metric.test_n != len(actual) or
                str(metric.test_start) != str(actual.index[0].date()) or
                str(metric.test_end) != str(actual.index[-1].date()) or rows.predicted.iloc[0] == 0):
            raise ValueError(f"Prediction dates, actual prices, or split disagree for {metric.symbol}/{metric.model}.")
        errors = rows.predicted.to_numpy() - rows.actual.to_numpy()
        checked = np.array([np.sqrt(np.mean(errors ** 2)), np.mean(np.abs(errors)),
                            rows.predicted.iloc[-1] / rows.predicted.iloc[0] - 1])
        difference = float(np.max(np.abs(checked - np.array(
            [metric.rmse, metric.mae, metric.predicted_period_return]))))
        maximum_metric_error = max(maximum_metric_error, difference)
        if difference > 1e-6:
            raise ValueError(f"Metrics disagree with predictions for {metric.symbol}/{metric.model}.")
        expected_count += len(rows)
    if len(predictions) != expected_count:
        raise ValueError("Prediction files contain unmatched model/stock rows.")
    return {"metrics": combined, "metric_rows": len(metrics), "prediction_rows": len(predictions),
            "stocks": len(SCREENED), "models": ["RF", "XGB", "LSTM"],
            "prediction_rows_by_model": {model: int((predictions.model == model).sum())
                                         for model in ("RF", "XGB", "LSTM")},
            "maximum_metric_error": maximum_metric_error}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_csv(root: Path, name: str) -> pd.DataFrame:
    path = root / "outputs" / "tables" / name
    cols = pd.read_csv(path, nrows=0).columns
    types = {c: str for c in ("symbol", "stock", "name") if c in cols}
    return pd.read_csv(path, dtype=types)


def load_evidence(root: Path) -> dict:
    tables = {p.name: load_csv(root, p.name) for p in sorted((root / "outputs/tables").glob("*.csv"))}
    expected = CORE_TABLES
    if not expected.issubset(tables):
        raise ValueError(f"Missing checked tables: {sorted(expected - tables.keys())}")
    raw = {}
    for folder in ("stocks", "etfs"):
        for p in sorted((root / "data" / folder).glob("*_daily.xlsx")):
            code = p.name.removesuffix("_daily.xlsx")
            df = pd.read_excel(p, usecols=["date", "close"], engine="openpyxl")
            df["date"] = pd.to_datetime(df["date"])
            df = df.sort_values("date").set_index("date")
            if df.index.has_duplicates or df["close"].isna().any() or (df["close"] <= 0).any():
                raise ValueError(f"Invalid original series: {p}")
            raw[code] = df["close"]
    if len(raw) != 40:
        raise ValueError("Expected exactly thirty stocks and ten ETFs.")
    perf = tables["presentation_price_performance.csv"].set_index("name")
    wealth = tables["presentation_buy_and_hold_wealth.csv"].copy()
    wealth["date"] = pd.to_datetime(wealth["date"])
    if len(wealth) != 218 or str(wealth["date"].iloc[0].date()) != "2023-01-03":
        raise ValueError("The report's stated evaluation interval no longer matches the tables.")
    weights = tables["presentation_weights_normalized.csv"].set_index("symbol")
    selected = pd.concat({s: raw[s] for s in FINAL}, axis=1).loc[wealth["date"]]
    normalized = selected / selected.iloc[0]
    check = normalized.to_numpy() @ weights.loc[FINAL, ["MV", "BL", "1/N"]].to_numpy()
    wealth_error = float(np.max(np.abs(check - wealth[["MV", "BL", "1/N"]].to_numpy())))
    if wealth_error > 1e-10:
        raise ValueError("Saved historical wealth does not reconcile to the original prices.")
    # These are fixed claims in the editable narrative, so fail instead of
    # silently pairing an old narrative with changed numerical evidence.
    if not np.allclose(perf.loc[["MV", "BL", "1/N"], "period_return"],
                       [.40404811, .38712872, .39572169], atol=1e-7):
        raise ValueError("Performance changed; review and revise both narrative files before rebuilding.")
    etfs = perf.drop(index=["MV", "BL", "1/N"])
    wins = {s: {"return": int((etfs.period_return < perf.loc[s, "period_return"]).sum()),
                 "sharpe": int((etfs.sharpe < perf.loc[s, "sharpe"]).sum()),
                 "lower_volatility": int((etfs.volatility > perf.loc[s, "volatility"]).sum())}
            for s in ("MV", "BL", "1/N")}
    assert [wins[s]["return"] for s in wins] == [7, 7, 7]
    assert [wins[s]["sharpe"] for s in wins] == [8, 6, 7]
    assert [wins[s]["lower_volatility"] for s in wins] == [4, 4, 4]
    forecast = load_forecast_validation(root, tables, raw)
    figure_paths = sorted((root / "outputs/figures").rglob("*.png"))
    ccf_paths = [p for p in figure_paths if p.name.startswith("38_ccf_")]
    forecast_paths = [p for p in figure_paths if p.parent.name == "models" and p.name.startswith("forecast_")]
    representative_ccf = {"38_ccf_0050_00646.png", "38_ccf_2330_2317.png"}
    extra_ccf = [p for p in ccf_paths if p.name not in representative_ccf]
    return {"tables": tables, "raw": raw, "perf": perf, "wealth": wealth,
            "weights": weights, "wins": wins, "wealth_error": wealth_error,
            "forecast": forecast, "figure_paths": figure_paths,
            "extra_ccf_count": len(extra_ccf), "forecast_figure_count": len(forecast_paths)}


def figure_setup():
    times = Path("C:/Windows/Fonts/times.ttf")
    if times.exists():
        fm.fontManager.addfont(str(times))
    plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"],
                         "font.size": 10, "axes.labelsize": 10, "axes.titlesize": 10,
                         "xtick.labelsize": 10, "ytick.labelsize": 10,
                         "legend.fontsize": 10, "axes.linewidth": .65,
                         "lines.linewidth": 1.0, "savefig.facecolor": "white"})


def finish(fig, path):
    fig.savefig(path, dpi=300, facecolor="white")
    plt.close(fig)


def make_figures(e: dict, directory: Path) -> dict:
    figure_setup()
    directory.mkdir(parents=True, exist_ok=True)
    paths = {k: directory / f"{k}.png" for k in
             ("wealth", "frontiers", "historical_ml", "exploration", "correlations", "diagnostics")}
    w, raw, tables = e["wealth"], e["raw"], e["tables"]
    # 1: A detailed strategy panel and ten comparable benchmark small multiples.
    fig = plt.figure(figsize=(7, 5.4), constrained_layout=True)
    gs = fig.add_gridspec(4, 5, height_ratios=[2.0, .15, 1.0, 1.0])
    ax = fig.add_subplot(gs[0, :])
    styles = {"MV": (COLORS["MV"], "-"), "BL": (COLORS["BL"], "--"),
              "1/N": (COLORS["1/N"], ":"), "0050": (COLORS["ETF"], "-.")}
    for s, (color, ls) in styles.items():
        ax.plot(w.date, w[s] - 1, label=s, color=color, ls=ls, lw=1.4 if s == "MV" else 1)
    ax.set_ylabel("Cumulative price return")
    ax.yaxis.set_major_formatter(PercentFormatter(1))
    ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 3, 5, 7, 9, 11]))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b"))
    ax.set_xlim(w.date.iloc[0], w.date.iloc[-1])
    ax.set_title("(a) Historical allocations and 0050", loc="left")
    ax.legend(ncol=4, loc="upper left", frameon=False)
    ax.grid(axis="y", color=".85", lw=.4)
    etfs = list(e["perf"].index[3:])
    label_ax = fig.add_subplot(gs[1, :])
    label_ax.axis("off")
    label_ax.text(.5, .5, "(b) Each ETF (dashed purple) versus MV (solid blue)",
                  transform=label_ax.transAxes, ha="center", va="center", fontsize=10)
    for i, s in enumerate(etfs):
        a = fig.add_subplot(gs[2 + i // 5, i % 5])
        a.plot(w.date, w.MV - 1, color=COLORS["MV"], lw=.9)
        a.plot(w.date, w[s] - 1, color=COLORS["ETF"], ls="--", lw=1)
        a.set_title(f"{s}: {100 * (w[s].iloc[-1] - 1):.1f}%", loc="left", fontsize=10)
        a.set_ylim(-.3, 1.05)
        a.set_yticks([0, .5, 1])
        a.yaxis.set_major_formatter(PercentFormatter(1, decimals=0))
        a.set_xticks([w.date.iloc[0], w.date.iloc[-1]])
        a.set_xticklabels(["Jan", "Nov"])
        if i % 5:
            a.tick_params(labelleft=False)
        a.grid(axis="y", color=".85", lw=.4)
    finish(fig, paths["wealth"])
    # 2: Model-implied frontiers; identical scales make the input differences visible.
    fig, axes = plt.subplots(1, 2, figsize=(7, 3.15), constrained_layout=True)
    for ax, name in zip(axes, ("mv", "bl")):
        d = tables[f"{name}_frontier.csv"]
        best = d.loc[d.sharpe.idxmax()]
        minimum = d.loc[d.volatility.idxmin()]
        ax.plot(d.volatility, d.expected_return, color=COLORS[name.upper()], label="Frontier")
        ax.plot([0, best.volatility], [.01565, best.expected_return], color="#687785", ls="--", label="CML segment")
        ax.scatter([best.volatility], [best.expected_return], c=COLORS["1/N"], marker="*", s=65, label="Max Sharpe")
        ax.scatter([minimum.volatility], [minimum.expected_return], facecolors="white", edgecolors=COLORS["ETF"], marker="s", s=25, label="Min variance")
        ax.set_xlim(0, .32); ax.set_ylim(0, .56)
        ax.xaxis.set_major_formatter(PercentFormatter(1, decimals=0))
        ax.yaxis.set_major_formatter(PercentFormatter(1, decimals=0))
        ax.set_xlabel("Annual model volatility")
        ax.set_title("MV: sample means" if name == "mv" else "BL: posterior means")
        ax.grid(color=".85", lw=.4)
    axes[0].set_ylabel("Expected annual return")
    axes[1].legend(loc="upper left", frameon=False, fontsize=10)
    finish(fig, paths["frontiers"])
    # 3: All archived ML values, without pretending they are realizable returns.
    d = tables["historical_ml_returns_percent.csv"].sort_values("average", ascending=False)
    fig, ax = plt.subplots(figsize=(7, 4.65), constrained_layout=True)
    y = np.arange(len(d))
    ax.barh(y, d.average, color="#D9E8F0", edgecolor="#8AA8B9", height=.65, linewidth=.5, label="Average")
    for model, marker in (("xgboost", "+"), ("RF", "o"), ("LSTM", "s")):
        marker_colors = {"color": MODEL_COLORS[model]} if marker == "+" else {"facecolors": "white", "edgecolors": MODEL_COLORS[model]}
        ax.scatter(d[model], y, marker=marker, s=20, **marker_colors,
                   linewidths=.7, label="XGBoost" if model == "xgboost" else model, zorder=3)
    labels = [s + ("*" if s in FINAL else " (drop)" if s in ("6669", "2382") else "") for s in d.stock]
    ax.set_yticks(y, labels=labels); ax.invert_yaxis()
    ax.axvline(0, color="black", lw=.6)
    ax.set_xlim(-30, 72); ax.set_xticks([-20, 0, 20, 40, 60])
    ax.set_xlabel("Archived predicted-price-path change (%)")
    ax.grid(axis="x", color=".85", lw=.4)
    ax.legend(ncol=4, loc="upper center", bbox_to_anchor=(.55, 1.10), frameon=False)
    finish(fig, paths["historical_ml"])
    # 4: Every input distribution, plus a common-base view of the final six.
    fig, axes = plt.subplots(3, 1, figsize=(7, 5.5), constrained_layout=True,
                             gridspec_kw={"height_ratios": [1.25, 1, 1.3]})
    stocks = list(tables["stock_descriptive_statistics.csv"].symbol)
    etfs = list(tables["etf_descriptive_statistics.csv"].symbol)
    for ax, codes, title in ((axes[0], stocks, "(a) Thirty stock closing-price distributions"),
                             (axes[1], etfs, "(b) Ten ETF closing-price distributions")):
        boxes = ax.boxplot([raw[s].to_numpy() for s in codes], labels=codes, widths=.6, showfliers=False,
                   patch_artist=True,
                   medianprops={"color": "black", "linewidth": .8},
                   boxprops={"linewidth": .6}, whiskerprops={"linewidth": .6}, capprops={"linewidth": .6})
        for patch, code in zip(boxes["boxes"], codes):
            patch.set_facecolor(STOCK_COLORS.get(code, "#D9E8F0") if ax is axes[0] else "#EBCFE0")
            patch.set_alpha(.8)
        ax.tick_params(axis="x", rotation=90 if len(codes) > 10 else 0, labelsize=10)
        ax.set_ylabel("Close price")
        ax.set_title(title, loc="left")
    selected = pd.concat({s: raw[s] for s in FINAL}, axis=1).dropna()
    selected = selected / selected.iloc[0]
    for i, s in enumerate(FINAL):
        axes[2].plot(selected.index, selected[s], color=STOCK_COLORS[s], ls=["-", "--", ":", "-.", (0, (4, 1, 1, 1)), (0, (1, 2))][i], label=s)
    axes[2].set_ylabel("First price = 1")
    axes[2].set_ylim(top=float(selected.to_numpy().max()) * 1.25)
    axes[2].set_title("(c) Six selected stocks, indexed within their common history", loc="left")
    axes[2].xaxis.set_major_locator(mdates.YearLocator())
    axes[2].xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    axes[2].legend(ncol=6, loc="upper left", frameon=False, fontsize=10)
    finish(fig, paths["exploration"])
    # 5: A monotonic-luminance scale preserves ordered, signed values in both
    # color and grayscale; fixed [-1, 1] limits keep panels interpretable.
    corr = tables["stock_return_correlations.csv"].set_index("symbol")
    fig, ax = plt.subplots(figsize=(7, 5.55), constrained_layout=True)
    im = ax.imshow(corr.to_numpy(), cmap="cividis", vmin=-1, vmax=1, interpolation="nearest")
    ax.set_xticks(np.arange(30), corr.columns, rotation=90, fontsize=10)
    ax.set_yticks(np.arange(30), corr.index, fontsize=10)
    bar = fig.colorbar(im, ax=ax, shrink=.82, pad=.02, ticks=[-1, -.5, 0, .5, 1])
    bar.set_label("Pearson correlation of log returns")
    ax.set_xlabel("Stock"); ax.set_ylabel("Stock")
    finish(fig, paths["correlations"])
    # 6: Exact scalar diagnostic definitions, not a claim of full CRQA.
    fig, axes = plt.subplots(2, 2, figsize=(7, 5.15), constrained_layout=True)
    ccf_checks = []
    for ax, (a, b) in zip(axes[0], (("2330", "2317"), ("0050", "00646"))):
        pair = pd.concat([raw[a].rename(a), raw[b].rename(b)], axis=1).dropna()
        ret = np.diff(np.log(pair.to_numpy()), axis=0)
        x, y = ret[:, 0] - ret[:, 0].mean(), ret[:, 1] - ret[:, 1].mean()
        lags = np.arange(-20, 21)
        ccf = np.correlate(x, y, "full")[len(x) - 1 + lags] / np.sqrt(x @ x * (y @ y))
        ax.vlines(lags, 0, ccf, color=COLORS["MV"] if a == "2330" else COLORS["BL"], lw=.8)
        ci = 1.96 / np.sqrt(len(x))
        ax.axhline(ci, color=".5", ls="--", lw=.7); ax.axhline(-ci, color=".5", ls="--", lw=.7)
        ax.axhline(0, color="black", lw=.5)
        ax.set_xlabel("Lag (observations)"); ax.set_ylabel("CCF")
        ax.set_title(f"{a} / {b}: log returns")
        ccf_checks.append({"pair": [a, b], "n": len(x), "peak_lag": int(lags[np.argmax(np.abs(ccf))]),
                           "peak_ccf": float(ccf[np.argmax(np.abs(ccf))])})
    for ax, (a, b) in zip(axes[1], (("2881", "2882"), ("2412", "6505"))):
        pair = pd.concat([raw[a].rename(a), raw[b].rename(b)], axis=1).dropna()
        z = (pair - pair.mean()) / pair.std(ddof=1)
        rp = np.abs(z[a].to_numpy()[:, None] - z[b].to_numpy()[None, :]) <= .1
        ax.imshow(rp, cmap="Blues", vmin=0, vmax=1, origin="lower", aspect="auto",
                  extent=[1, len(pair), 1, len(pair)], interpolation="nearest")
        ax.set_xlabel(f"{b}: observation index"); ax.set_ylabel(f"{a}: observation index")
        ax.set_title("Scalar price cross-recurrence")
    finish(fig, paths["diagnostics"])
    e["ccf_checks"] = ccf_checks
    return paths


def register_fonts(font_dir: Path):
    required = [font_dir / p for p in ("times.ttf", "timesbd.ttf", "timesi.ttf", "timesbi.ttf", "mingliu.ttc")]
    if not all(p.is_file() for p in required):
        raise FileNotFoundError("Provide --font-dir with Times TTF files and mingliu.ttc (PMingLiU).")
    for name, file in (("TNR", "times.ttf"), ("TNR-Bold", "timesbd.ttf"),
                       ("TNR-Italic", "timesi.ttf"), ("TNR-BoldItalic", "timesbi.ttf")):
        pdfmetrics.registerFont(TTFont(name, str(font_dir / file)))
    pdfmetrics.registerFontFamily("TNR", normal="TNR", bold="TNR-Bold", italic="TNR-Italic", boldItalic="TNR-BoldItalic")
    pdfmetrics.registerFont(TTFont("CJK", str(font_dir / "mingliu.ttc"), subfontIndex=1))
    pdfmetrics.registerFontFamily("CJK", normal="CJK", bold="CJK", italic="CJK", boldItalic="CJK")


def read_content(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    sections = {}
    for match in re.finditer(r"^## ([a-z_]+)\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S):
        sections[match.group(1)] = match.group(2).strip()
    if len(sections) != 38:
        raise ValueError(f"Expected 38 narrative/caption sections in {path}, found {len(sections)}")
    return sections


def markup(text: str) -> str:
    text = text.replace("−", "-").replace("–", "-").replace("—", "-").replace("\u00a0", " ")
    text = html.escape(text)
    text = re.sub(r"\*\*(.*?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`([^`]+)`", r"<i>\1</i>", text)
    return re.sub(r"([\u2e80-\u9fff\uf900-\ufaff\u3000-\u303f\uff00-\uffef]+)",
                  r'<font name="CJK">\1</font>', text)


def styles(lang):
    wrap = "CJK" if lang == "zh" else None
    body = ParagraphStyle("body", fontName="TNR", fontSize=10, leading=12,
                          alignment=TA_JUSTIFY, spaceAfter=5, wordWrap=wrap,
                          allowWidows=0, allowOrphans=0,
                          bulletFontName="TNR", bulletFontSize=10,
                          # ReportLab hangs CJK closing punctuation beyond the
                          # paragraph width. Reserve one glyph inside the frame.
                          rightIndent=10 if lang == "zh" else 0)
    return {
        "body": body,
        "head": ParagraphStyle("head", parent=body, fontName="TNR-Bold", fontSize=11,
                               leading=13, spaceBefore=2, spaceAfter=5, alignment=TA_LEFT),
        "caption": ParagraphStyle("caption", parent=body, spaceAfter=7, alignment=TA_LEFT),
        "cell": ParagraphStyle("cell", parent=body, alignment=TA_LEFT, spaceAfter=0, rightIndent=0),
        "title": ParagraphStyle("title", parent=body, fontName="TNR-Bold", fontSize=14,
                                 leading=16, alignment=TA_CENTER, spaceAfter=0, rightIndent=0),
        "center": ParagraphStyle("center", parent=body, alignment=TA_CENTER, spaceAfter=0, rightIndent=0),
        "course": ParagraphStyle("course", parent=body, fontName="TNR-Italic", alignment=TA_CENTER,
                                 spaceAfter=0, rightIndent=0),
    }


def paragraphs(text, sty):
    result = []
    for block in re.split(r"\n\s*\n", text.strip()):
        if block.startswith("- "):
            for line in block.splitlines():
                result.append(Paragraph(markup(line.removeprefix("- ")), sty, bulletText="•"))
        elif block:
            result.append(Paragraph(markup(" ".join(block.splitlines())), sty))
    return result


def table(data, widths, s, bold_rows=()):
    rows = []
    for i, row in enumerate(data):
        cells = []
        for cell in row:
            text = markup(str(cell))
            if i == 0 or i in bold_rows:
                text = "<b>" + text + "</b>"
            cells.append(Paragraph(text, s["cell"]))
        rows.append(cells)
    t = Table(rows, colWidths=widths, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3), ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 1), ("BOTTOMPADDING", (0, 0), (-1, -1), 1),
        ("LINEABOVE", (0, 0), (-1, 0), .65, colors.black),
        ("LINEBELOW", (0, 0), (-1, 0), .45, colors.black),
        ("LINEBELOW", (0, -1), (-1, -1), .65, colors.black),
    ]))
    return t


def place_flow(cv, items, x, top, width, height, label):
    pending = list(items)
    frame = Frame(x, top - height, width, height, leftPadding=0, rightPadding=0,
                  topPadding=0, bottomPadding=0, showBoundary=0)
    frame.addFromList(pending, cv)
    if pending:
        preview = getattr(pending[0], "text", str(pending[0]))[:100]
        raise ValueError(f"Layout overflow in {label}: {preview}")


def draw_table(cv, data, widths, x, top, s, label, bold_rows=()):
    t = table(data, widths, s, bold_rows)
    _, height = t.wrap(sum(widths), HEIGHT)
    if height > HEIGHT:
        raise ValueError(f"Table too tall: {label}")
    t.drawOn(cv, x, top - height)
    return top - height


def caption(cv, text, prefix, top, s):
    p = Paragraph("<b>" + markup(prefix) + "</b> " + markup(text), s["caption"])
    _, h = p.wrap(WIDTH, HEIGHT)
    p.drawOn(cv, LEFT, top - h)
    return top - h - 8


def draw_image(cv, path, top, inches):
    h = inches * 72
    cv.drawImage(str(path), LEFT, top - h, width=WIDTH, height=h, preserveAspectRatio=True,
                 anchor="c", mask="auto")
    return top - h - 4


LABELS = {
    "en": {"abstract": "Abstract", "overview": "1  Overview", "objective": "1.1  Objective",
           "scope": "1.2  Scope and evidence", "data": "2  Data and Methods", "screening": "2.1  Correlation screening",
           "forecasting": "2.2  Forecasting design", "allocation": "2.3  Portfolio construction",
           "measurement": "2.4  Performance definitions", "main_results": "3  Results / Key Takeaways",
           "risk_takeaways": "3.1  Return and risk rankings", "wealth_interpretation": "3.2  Cumulative price returns",
           "benchmark_interpretation": "3.3  ETF counterexamples", "concentration": "4  Allocation and Concentration",
           "frontiers": "4.1  Model-implied frontiers", "historical_ml": "5  Historical Forecasting Evidence",
           "model_validation": "5.1  Verification scope", "exploration": "6  Exploratory Evidence",
           "stationarity": "6.1  Unit-root tests", "dependence": "6.2  Correlation structure",
           "clique_note": "6.3  Non-unique screening", "diagnostics": "6.4  Cross-correlation examples",
           "recurrence": "6.5  Scalar recurrence", "limitations": "7  Limitations", "reconstruction": "7.1  Reconstruction sensitivity",
           "conclusion": "7.2  Conclusion", "catalog": "8  Figures & Tables", "references": "References"},
    "zh": {"abstract": "摘要（Abstract）", "overview": "1  概述（Overview）", "objective": "1.1  研究目標（Objective）",
           "scope": "1.2  範圍與證據", "data": "2  資料與研究方法", "screening": "2.1  相關性篩選",
           "forecasting": "2.2  預測設計", "allocation": "2.3  投資組合建構", "measurement": "2.4  績效定義",
           "main_results": "3  結果與重點（Results / Key Takeaways）", "risk_takeaways": "3.1  報酬與風險排名",
           "wealth_interpretation": "3.2  累積價格報酬路徑", "benchmark_interpretation": "3.3  ETF 比較的例外",
           "concentration": "4  資產配置與集中程度", "frontiers": "4.1  模型預期效率前緣",
           "historical_ml": "5  歷史預測證據", "model_validation": "5.1  驗證範圍",
           "exploration": "6  探索性證據", "stationarity": "6.1  單根檢定", "dependence": "6.2  相關結構",
           "clique_note": "6.3  非唯一的篩選結果", "diagnostics": "6.4  交叉相關範例", "recurrence": "6.5  純量交叉復發",
           "limitations": "7  研究限制", "reconstruction": "7.1  重建與設定敏感性", "conclusion": "7.2  結論",
           "catalog": "8  圖與表（Figures & Tables）", "references": "參考文獻"},
}


def build_pdf(root: Path, e: dict, assets: dict, lang: str) -> Path:
    directory = root / "reports" / f"report_{lang}"
    content = read_content(directory / "content.md")
    s, labels = styles(lang), LABELS[lang]
    stem = f"report_{lang}"
    out = directory / f"{stem}.pdf"
    temp = directory / f".{stem}.building.pdf"
    title = "Beyond ETFs: Stock Forecasting and Portfolio Comparison" if lang == "en" else "超越 ETF：股票預測與投資組合比較"
    cv = canvas.Canvas(str(temp), pagesize=(PAGE_W, PAGE_H), pageCompression=1)
    cv.setTitle(title)
    cv.setAuthor("; ".join(AUTHORS_EN if lang == "en" else AUTHORS_ZH))
    cv.setSubject(f"Spring 2024 course project; reconstruction reviewed {REVIEW_DATE}; OSDI 2024-style layout")
    cv.setCreator("scripts/build_reports.py (ReportLab; source-backed color figures)")
    page = 0

    def start(title=None):
        nonlocal page
        page += 1
        cv.setFont("TNR", 10)
        cv.drawCentredString(PAGE_W / 2, 47, str(page))
        if title:
            p = Paragraph(markup(title), s["head"])
            _, h = p.wrap(WIDTH, HEIGHT)
            p.drawOn(cv, LEFT, TOP - h)
            return TOP - h - 9
        return TOP

    def end():
        cv.showPage()

    def block(key, heading=True):
        a = [Paragraph(markup(labels[key]), s["head"])] if heading else []
        return a + paragraphs(content[key], s["body"])

    def columns(left, right, top=TOP, bottom=BOTTOM, label=""):
        place_flow(cv, left, LEFT, top, COL, top - bottom, f"{lang} p{page} left {label}")
        place_flow(cv, right, LEFT + COL + GAP, top, COL, top - bottom, f"{lang} p{page} right {label}")

    def cap(key, prefix, top):
        return caption(cv, content[key], prefix, top, s)

    try:
        # Page 1: title, authors, affiliation, coursework and research term.
        top = start()
        title_p = Paragraph(markup(title), s["title"])
        _, h = title_p.wrap(WIDTH, HEIGHT)
        title_p.drawOn(cv, LEFT, top - h); top -= h + 12
        names = ", ".join(AUTHORS_EN) if lang == "en" else "、".join(AUTHORS_ZH)
        p = Paragraph(markup(names), s["center"]); _, h = p.wrap(WIDTH, HEIGHT)
        p.drawOn(cv, LEFT, top - h); top -= h + 5
        p = Paragraph(markup(AFFILIATIONS[lang]), s["center"]); _, h = p.wrap(WIDTH, HEIGHT)
        p.drawOn(cv, LEFT, top - h); top -= h + 9
        course = "Big Data Analytics Coursework" if lang == "en" else "巨量資料分析課程期末專題 | 授課教師：鄭順林"
        p = Paragraph(markup(course), s["course"]); _, h = p.wrap(WIDTH, HEIGHT)
        p.drawOn(cv, LEFT, top - h); top -= h + 2
        p = Paragraph(markup(TERM), s["course"]); _, h = p.wrap(WIDTH, HEIGHT)
        p.drawOn(cv, LEFT, top - h); top -= h + 18
        left = block("abstract") + block("overview")
        coverage = ("Observation coverage: 28 stock series have 1,195 observations; 2603 has 1,188 and 6669 has 1,144. Nine ETFs have 1,195 observations; 00830 has 1,120. Common six-stock/ten-ETF evaluation: 218 prices, 217 returns." if lang == "en" else
                    "觀測覆蓋：28 檔股票各有 1,195 筆，2603 為 1,188 筆，6669 為 1,144 筆；九檔 ETF 各有 1,195 筆，00830 為 1,120 筆。六股與十檔 ETF 的共同評估窗口為 218 筆價格、217 筆報酬。")
        right = block("objective") + block("scope") + [Spacer(1, 6)] + paragraphs(coverage, s["body"])
        conventions = ("Benchmark ETFs: 0050, 0056, 006208, 00713, 00712, 00692, 00646, 00757, 00830, and 00733." if lang == "en" else
                       "ETF 對照組：0050、0056、006208、00713、00712、00692、00646、00757、00830、00733。")
        right += paragraphs(conventions, s["body"])
        columns(left, right, top=top, label="introduction")
        end()
        # Page 2: reproducible definitions and compact model/input tables.
        top = start()
        split_data = [["Series", "Train", "Test", "First test"],
                      ["Standard (20)", "940", "235", "2022-12-08"],
                      ["2603", "934", "234", "2022-12-09"],
                      ["6669", "899", "225", "2022-12-22"]]
        left = block("data") + block("screening") + block("forecasting")
        left += [Spacer(1, 5), table(split_data, [76, 36, 36, COL - 148], s)]
        bl = e["tables"]["bl_annual_returns.csv"]
        bl_data = [["Stock", "Prior %", "View %", "Post. %"]] + [
            [r.symbol, f"{100*r.prior:.2f}", f"{100*r.view:.2f}", f"{100*r.posterior:.2f}"] for r in bl.itertuples()]
        right = block("allocation") + [table(bl_data, [48, 64, 64, COL - 176], s), Spacer(1, 5)]
        omega = "Omega diagonal: (0.015625, 0.0225, 0.015625, 0.005625, 0.0025, 0.0025), in the table's asset order."
        right += paragraphs(omega if lang == "en" else "Omega 對角線依表中股票順序為 (0.015625, 0.0225, 0.015625, 0.005625, 0.0025, 0.0025)。", s["body"])
        right += block("measurement")
        equations = ("W(t) = sum_i w_i P_i(t) / P_i(0)\n\nr(t) = W(t) / W(t-1) - 1\n\nSharpe = [252 mean(r) - 0.01565] / [sd(r) sqrt(252)]")
        right += paragraphs(equations, s["body"])
        columns(left, right, top=top, label="methods")
        end()
        # Page 3: all thirteen instruments, no omitted benchmark counterexample.
        top = start(labels["main_results"])
        data = [["Name", "Period %", "Geo. ann. %", "Ann. vol. %", "Sharpe", "MDD %"]]
        for name, row in e["perf"].iterrows():
            data.append([name, f"{100*row.period_return:.2f}", f"{100*row.annualized_return:.2f}",
                         f"{100*row.volatility:.2f}", f"{row.sharpe:.3f}", f"{100*row.max_drawdown:.2f}"])
        top = draw_table(cv, data, [58, 85, 93, 93, 78, 97], LEFT, top, s, "performance", (1, 2, 3)) - 7
        top = cap("caption_performance", "Table 1." if lang == "en" else "表 1。", top)
        win_table = [["Allocation", "Return wins", "Sharpe wins", "Lower vol."]] + [
            [name, f"{e['wins'][name]['return']}/10", f"{e['wins'][name]['sharpe']}/10",
             f"{e['wins'][name]['lower_volatility']}/10"] for name in ("MV", "BL", "1/N")]
        columns(block("main_results", False) + [Spacer(1, 8), table(win_table, [65, 58, 61, COL-184], s)],
                block("risk_takeaways"), top=top - 4, label="results")
        end()
        # Page 4: all thirteen wealth series use consistent colors and line styles.
        top = start("Buy-and-hold cumulative price returns" if lang == "en" else "買入持有累積價格報酬")
        top = draw_image(cv, assets["wealth"], top, 5.4)
        top = cap("caption_wealth", "Figure 1." if lang == "en" else "圖 1。", top)
        columns(block("wealth_interpretation"), block("benchmark_interpretation"), top=top, label="wealth")
        end()
        # Page 5: exact weights followed by the two distinct optimization inputs.
        top = start("Weights and annual model frontiers" if lang == "en" else "資金權重與年度模型效率前緣")
        w, rw = e["weights"], e["tables"]["recomputed_in_sample_weights.csv"].set_index("symbol")
        data = [["Stock", "Hist. MV %", "Hist. BL %", "Equal %", "Refit MV %", "Refit BL %"]]
        for code in FINAL:
            data.append([code, f"{100*w.loc[code,'MV']:.2f}", f"{100*w.loc[code,'BL']:.2f}",
                         f"{100*w.loc[code,'1/N']:.2f}", f"{100*rw.loc[code,'MV']:.2f}", f"{100*rw.loc[code,'BL']:.2f}"])
        top = draw_table(cv, data, [50, 91, 91, 80, 96, 96], LEFT, top, s, "weights") - 5
        top = cap("caption_weights", "Table 2." if lang == "en" else "表 2。", top)
        top = draw_image(cv, assets["frontiers"], top, 3.15)
        top = cap("caption_frontiers", "Figure 2." if lang == "en" else "圖 2。", top)
        columns(block("concentration"), block("frontiers"), top=top, label="allocation")
        end()
        # Page 6: keep the archived ranking distinct from current retraining.
        top = start(labels["historical_ml"])
        top = draw_image(cv, assets["historical_ml"], top, 4.65)
        top = cap("caption_ml", "Figure 3." if lang == "en" else "圖 3。", top)
        check_table = [["Check", "Setting", "RMSE"]]
        if e["forecast"] is not None:
            current = e["forecast"]["metrics"].set_index(["symbol", "model"])
            for model, setting in (("RF", "500 trees"), ("XGB", "10 rounds"), ("LSTM", "50 epochs")):
                check_table.append([f"2330 {model}", setting, f"{current.loc[('2330', model), 'rmse']:.4f}"])
        else:
            check_table += [["2330 RF", "500 trees", "9.9145"], ["2330 LSTM", "50 epochs", "15.1320"]]
        columns(block("historical_ml", False), block("model_validation") + [table(check_table, [78, 88, COL-166], s)],
                top=top, label="ML")
        end()
        # Page 7: distributions are not return rankings; the trend panel is indexed.
        top = start(labels["exploration"])
        top = draw_image(cv, assets["exploration"], top, 5.5)
        top = cap("caption_eda", "Figure 4." if lang == "en" else "圖 4。", top)
        adf_table = [["ADF at 5%", "Reject", "Do not reject"], ["Price level", "1/40", "39/40"],
                     ["Log returns", "40/40", "0/40"]]
        columns(block("exploration", False), block("stationarity") + [table(adf_table, [95, 60, COL-155], s)],
                top=top, label="EDA")
        end()
        # Page 8: all thirty labels retain their actual asset codes.
        top = start(labels["dependence"])
        top = draw_image(cv, assets["correlations"], top, 5.55)
        top = cap("caption_correlations", "Figure 5." if lang == "en" else "圖 5。", top)
        columns(block("dependence", False), block("clique_note"), top=top, label="correlations")
        end()
        # Page 9: different source series and metrics are explicitly labeled.
        top = start("Cross-correlation and scalar recurrence" if lang == "en" else "交叉相關與純量交叉復發")
        top = draw_image(cv, assets["diagnostics"], top, 5.15)
        top = cap("caption_diagnostics", "Figure 6." if lang == "en" else "圖 6。", top)
        formula = "RP(i,j) = 1 if abs(z_x(i) - z_y(j)) <= 0.1; otherwise 0."
        columns(block("diagnostics"), block("recurrence") + paragraphs(formula, s["body"]),
                top=top, label="diagnostics")
        end()
        # Page 10: historical and refit realized statistics remain separate.
        top = start()
        data = [["Fit", "Return %", "Vol. %", "Sharpe"]]
        for prefix, df in (("Hist.", e["perf"].iloc[:3]),
                           ("Refit", e["tables"]["recomputed_in_sample_performance.csv"].set_index("name"))):
            for name, row in df.iterrows():
                data.append([f"{prefix} {name}", f"{100*row.period_return:.2f}", f"{100*row.volatility:.2f}", f"{row.sharpe:.3f}"])
        right = block("reconstruction") + [table(data, [72, 56, 56, COL-184], s)]
        right += paragraphs(("Table 3. " if lang == "en" else "表 3。") + content["caption_recomputed"], s["caption"])
        right += block("conclusion")
        commands = "Rscript --vanilla run.R\n\npython scripts/build_reports.py"
        right += paragraphs(commands, s["body"])
        columns(block("limitations"), right, top=top, label="limitations")
        end()
        # Page 11: catalogs cover every generated numerical and graphical output.
        top = start(labels["catalog"])
        catalog_intro = Paragraph(markup(content["catalog"]), s["body"])
        _, intro_height = catalog_intro.wrap(WIDTH, HEIGHT)
        catalog_intro.drawOn(cv, LEFT, top - intro_height)
        top -= intro_height + 8
        purposes = {
            "adf_tests.csv": "Unit-root tests, 40 series",
            "bl_annual_returns.csv": "Annual BL prior, views, posterior",
            "bl_frontier.csv": "BL annual model frontier",
            "etf_descriptive_statistics.csv": "Ten ETF price distributions",
            "historical_ml_returns_percent.csv": "Archived 22-stock ML summaries",
            "mv_frontier.csv": "MV annual model frontier",
            "presentation_buy_and_hold_wealth.csv": "Historical wealth, 218 dates",
            "presentation_price_performance.csv": "Historical allocations + ten ETFs",
            "presentation_weights_normalized.csv": "Normalized historical allocations",
            "recomputed_in_sample_performance.csv": "Refit realized performance",
            "recomputed_in_sample_wealth.csv": "Refit realized wealth, 218 dates",
            "recomputed_in_sample_weights.csv": "Refit initial allocations",
            "stock_descriptive_statistics.csv": "Thirty stock price distributions",
            "stock_return_correlations.csv": "Thirty-stock correlation matrix",
            "stock_selection_comparison.csv": "Historical / tied clique membership",
        }
        if e["forecast"] is not None:
            purposes["combined_forecast_metrics.csv"] = "Current 22-stock / three-model metrics"
        data = [["CSV in outputs/tables/", "Rows", "Evidence"]]
        for name in sorted(purposes):
            data.append([name, str(len(e["tables"][name])), purposes[name]])
        top = draw_table(cv, data, [239, 34, 231], LEFT, top, s, "CSV catalog") - 5
        top = cap("caption_datasets", "Table 4." if lang == "en" else "表 4。", top)
        mapping = {
            "31_etf_price_boxplots.png": "Fig. 4; descriptive tables",
            "32_etf_price_trends.png": "Exploration; full source retained",
            "34_stock_price_boxplots.png": "Fig. 4; descriptive tables",
            "35_stock_price_trends.png": "Fig. 4; full source retained",
            "38_ccf_0050_00646.png": "Fig. 6, top right",
            "38_ccf_2330_2317.png": "Fig. 6, top left",
            "39_recurrence_2412_6505.png": "Fig. 6, bottom right",
            "39_recurrence_2881_2882.png": "Fig. 6, bottom left",
            "41_stock_return_correlations.png": "Fig. 5",
            "46_portfolio_weights.png": "Table 2 (exact percentages)",
            "47_mv_frontier.png": "Fig. 2, left",
            "48_bl_frontier.png": "Fig. 2, right",
            "49_return_comparison.png": "Table 1",
            "50_volatility_comparison.png": "Table 1",
            "51_sharpe_comparison.png": "Table 1",
            "52_cumulative_returns.png": "Fig. 1; all series retained",
        }
        data = [["PNG in outputs/figures/", "Report location"]] + [[k, v] for k, v in mapping.items()]
        if e["extra_ccf_count"]:
            data.append([f"38_ccf_*.png ({e['extra_ccf_count']} additional)", "All stock pairs; 6.4 diagnostics"])
        if e["forecast_figure_count"]:
            data.append([f"models/forecast_*.png ({e['forecast_figure_count']} stocks)", "Current predictions; 5.1 verification"])
        top = draw_table(cv, data, [283, 221], LEFT, top, s, "figure catalog") - 5
        top = cap("caption_original_figures", "Table 5." if lang == "en" else "表 5。", top)
        if top < BOTTOM:
            raise ValueError(f"{lang} catalog page exceeds the text block")
        end()
        # References are not counted toward the OSDI body-page limit. No appendix.
        top = start(labels["references"])
        refs = [
            "[1] Spring 2024 Big Data Analytics project team. Beyond ETFs (超越 ETF). Course presentation, Spring 2024. Local artifact: docs/presentation.pdf; methods and results on slides 31-54.",
            "[2] Min-Yuh Day and Jian-Ting Lin. Artificial Intelligence for ETF Market Prediction and Portfolio Optimization. In Proceedings of the 2019 IEEE/ACM International Conference on Advances in Social Networks Analysis and Mining (ASONAM), 2019. DOI: 10.1145/3341161.3344822. Preserved paper: references/papers/ai_etf_portfolio_optimization_2019.pdf.",
            f"[3] Project reconstruction artifacts, reviewed {REVIEW_DATE}. R/config.R, R/data.R, R/models.R, R/portfolio.R, R/plots.R; outputs/tables/; outputs/models/; outputs/RUN_NOTES.txt; docs/VALIDATION.md. {len(e['tables'])} CSV tables and {len(e['figure_paths'])} generated PNG figures, including extended CCF and prediction figures when present.",
            "[4] USENIX. OSDI '24 Requirements for Authors. Accessed 2026-10-20. " + RULES,
            "[5] USENIX. Templates for Conference Papers. Accessed 2026-10-20. " + TEMPLATE,
        ]
        left = paragraphs("\n\n".join(refs[:3]), s["body"])
        right = paragraphs("\n\n".join(refs[3:]), s["body"])
        format_note = ("Format note. US Letter; centered 7 x 9 inch text area; two 3.335 inch columns separated by 0.33 inch; body type 10 pt with 12 pt leading. Times New Roman is embedded for Latin text and PMingLiU for Chinese. Body: eleven pages; references: one page. " if lang == "en" else
                       "版面說明：US Letter，置中的 7 x 9 英吋文字區，兩欄各 3.335 英吋、欄距 0.33 英吋，本文 10 pt、行距 12 pt。西文內嵌 Times New Roman，中文內嵌 PMingLiU。正文十一頁、參考文獻一頁，不設附錄。")
        format_note += ("This is an author-named course report, not an anonymous conference submission. No conference submission or acceptance is claimed. " if lang == "en" else
                        "本稿為署名課程報告，並非匿名會議投稿稿件，亦不表示曾投稿或獲錄取。")
        format_note += ("Report plots use color with line styles or marker shapes as additional visual cues. The correlation scale has monotonic luminance for grayscale printing." if lang == "en" else
                        "報告圖採彩色，保留線型及標記輔助辨識；相關矩陣色階亮度單調，兼顧黑白列印。")
        right += [Spacer(1, 12)] + paragraphs(format_note, s["body"])
        preserved = ("Archived historical results. archive/historical-results/figures/ contains thirty stock decompositions, four ETF decompositions, two original recurrence images, and one original MV frontier. These thirty-seven project outputs are archival context, distinct from the current figures cataloged above and from external literature in references/papers/." if lang == "en" else
                     "歷史結果封存：archive/historical-results/figures/ 保存三十張個股分解、四張 ETF 分解、兩張原始復發圖及一張原 MV 前緣，共三十七份自行產生的舊分析輸出。這些檔案供歷史追溯，與表 5 的目前重算圖及 references/papers/ 的外部文獻分開。")
        right += paragraphs(preserved, s["body"])
        columns(left, right, top=top, label="references")
        end()
        if page != 12:
            raise ValueError("Unexpected page composition")
        cv.save()
        temp.replace(out)
    except Exception:
        try:
            cv.save()
        except Exception:
            pass
        temp.unlink(missing_ok=True)
        raise
    return out


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--font-dir", type=Path, default=Path("C:/Windows/Fonts"))
    args = parser.parse_args(argv)
    root = args.root.resolve()
    register_fonts(args.font_dir)
    e = load_evidence(root)
    historical_figures = sorted(p for p in (root / HISTORICAL_FIGURES).rglob("*") if p.is_file())
    historical_manifest = root / "archive/historical-results/figure_manifest.json"
    archive_record = json.loads(historical_manifest.read_text(encoding="utf-8"))
    archived_hashes = {item["path"]: item["sha256"] for item in archive_record["files"]}
    actual_hashes = {p.relative_to(root).as_posix(): sha(p) for p in historical_figures}
    if len(historical_figures) != 37 or archive_record["file_count"] != 37 or actual_hashes != archived_hashes:
        raise ValueError("Historical figure archive no longer matches its 37-file provenance manifest.")
    assets = make_figures(e, root / "reports/assets")
    outputs = [build_pdf(root, e, assets, lang) for lang in ("zh", "en")]
    sources = sorted((root / "outputs/tables").glob("*.csv"))
    sources += e["figure_paths"]
    sources += sorted((root / "outputs/models").glob("*.csv"))
    sources += sorted((root / "data").rglob("*.xlsx"))
    sources += [root / "docs/presentation.pdf", root / "docs/VALIDATION.md",
                root / "outputs/RUN_NOTES.txt", root / "references/papers/ai_etf_portfolio_optimization_2019.pdf"]
    sources += sorted((root / "R").glob("*.R"))
    sources += [root / "run.R", root / "scripts/build_reports.py", root / "scripts/requirements-reports.txt",
                root / "scripts/train_lstm.py", root / "scripts/requirements-lstm.txt",
                root / "tests/run_tests.R", root / "tests/test_lstm.py",
                root / "reports/report_zh/content.md", root / "reports/report_en/content.md"]
    sources += historical_figures
    sources += [historical_manifest]
    if e["forecast"] is not None:
        evidence_dir = root / "outputs/full_run/2026-10-21"
        sources += [p for name in ("verification.json", "r_execution.json", "r_tests.log",
                    "r_full_pipeline.log", "lstm_full_run.log", "lstm_full_run_validation.json",
                    "native-package-versions.csv") if (p := evidence_dir / name).is_file()]
    manifest = {
        "research_term": TERM, "data_cutoff": "2023-11-30", "reconstruction_review_date": REVIEW_DATE,
        "authors": {"zh": AUTHORS_ZH, "en": AUTHORS_EN},
        "affiliations": AFFILIATIONS,
        "report_variants": {
            "author_named": {"files": [f"reports/report_{lang}/report_{lang}.pdf" for lang in ("zh", "en")],
                             "includes_course_term": True},
        },
        "format": {"paper": "US Letter", "text_block_inches": [7, 9], "columns": 2,
                   "column_gap_inches": .33, "body_font_pt": 10, "leading_pt": 12,
                   "body_pages": 11, "reference_pages": 1, "appendices": 0,
                   "latin_font": "Times New Roman (embedded)", "chinese_font": "PMingLiU (embedded)",
                   "figure_color_mode": "color", "strategy_palette": COLORS,
                   "stock_palette": STOCK_COLORS, "model_palette": MODEL_COLORS,
                   "figure_label_minimum_pt": 10,
                   "correlation_colormap": "cividis", "correlation_scale": [-1, 1],
                   "correlation_luminance": "monotonic", "recurrence_colormap": "Blues",
                   "basis": [RULES, TEMPLATE], "conference_submission_claimed": False},
        "source_counts": {"csv_tables": len(e["tables"]), "core_csv_tables": len(CORE_TABLES),
                          "generated_original_figures": len(e["figure_paths"]),
                          "core_analysis_figures": 16, "additional_stock_ccf_figures": e["extra_ccf_count"],
                          "stock_forecast_figures": e["forecast_figure_count"],
                          "model_csv_files": len(list((root / "outputs/models").glob("*.csv"))),
                          "raw_workbooks": sum(len(list((root / "data" / kind).glob("*_daily.xlsx")))
                                               for kind in ("stocks", "etfs")),
                          "historical_ml_workbooks": len(list((root / "data/historical").glob("*.xlsx"))),
                          "report_composite_figures": len(assets),
                          "report_pdf_count": len(outputs),
                          "preserved_historical_figures": len(historical_figures)},
        "numeric_checks": {"historical_wealth_max_abs_error": e["wealth_error"],
                           "benchmark_outperformance_counts": e["wins"], "ccf_examples": e["ccf_checks"],
                           "full_retraining": {key: value for key, value in e["forecast"].items() if key != "metrics"}
                           if e["forecast"] is not None else None},
        "sources": [{"path": p.relative_to(root).as_posix(), "sha256": sha(p)} for p in sources],
        "outputs": [{"path": p.relative_to(root).as_posix(), "sha256": sha(p)}
                    for p in outputs + list(assets.values())],
        "limitations": ["Same-window fitting/retrospective selection, not an out-of-sample strategy backtest",
                        "Price returns without distributions, costs, taxes, or corporate-action adjustment",
                        "Historical full RMSE exclusion table unavailable"] + (
                            ["No full twenty-two-stock retraining of all three model families",
                             "Native R XGBoost retraining not verified"] if e["forecast"] is None else []),
    }
    (root / "reports/report_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    for path in outputs:
        print(f"Built {path}: {path.stat().st_size:,} bytes; 11 body pages + 1 reference page")


if __name__ == "__main__":
    main()
