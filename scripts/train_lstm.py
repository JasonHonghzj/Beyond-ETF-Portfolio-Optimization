"""Train the presentation's two-layer PyTorch LSTM on local stock workbooks.

The R RF/XGB pipeline and this script use the same chronological split and
20-prior-close -> next-close target. Scaling is fitted on training data only.
Outputs describe one-step forecasts using observed prior closes; the predicted
period return is a price-path change, not a realized trading-strategy return.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import random
import sys

import numpy as np
import pandas as pd
import torch
from torch import nn


DEFAULT_SYMBOLS = (
    "2317", "2330", "2395", "2357", "3231", "2207", "2603", "3034",
    "3045", "2002", "6669", "1216", "2303", "3711", "2308", "2412",
    "2382", "2454", "2881", "2885", "2886", "6505",
)
METRIC_COLUMNS = (
    "symbol", "model", "rmse", "mae", "predicted_period_return",
    "test_start", "test_end", "train_n", "test_n",
)
PREDICTION_COLUMNS = ("date", "symbol", "model", "actual", "predicted")


def make_lagged_data(prices: pd.DataFrame, lookback: int = 20) -> dict:
    """Return oldest-to-newest input windows, next closes and aligned dates."""
    if isinstance(lookback, bool) or not isinstance(lookback, int) or lookback < 1:
        raise ValueError("lookback must be a positive integer")
    if not {"date", "close"}.issubset(prices.columns):
        raise ValueError("prices must contain date and close columns")
    data = prices.loc[:, ["date", "close"]].copy()
    data["date"] = pd.to_datetime(data["date"], errors="raise").dt.normalize()
    data["close"] = pd.to_numeric(data["close"], errors="raise")
    if data["date"].isna().any() or data["date"].duplicated().any():
        raise ValueError("stock prices must have valid, unique dates")
    data = data.sort_values("date").reset_index(drop=True)
    close = data["close"].to_numpy(dtype=np.float64)
    if not np.isfinite(close).all() or (close <= 0).any():
        raise ValueError("closing prices must be finite and positive")
    if len(close) <= lookback:
        raise ValueError("more than lookback price observations are required")
    windows = np.lib.stride_tricks.sliding_window_view(close, lookback + 1)
    dates = data["date"].to_numpy(dtype="datetime64[D]")
    return {
        "x": windows[:, :-1].copy(),
        "y": windows[:, -1].copy(),
        "dates": dates[lookback:],
        "feature_end_dates": dates[lookback - 1:-1],
    }


def split_lagged_data(dataset: dict, train_fraction: float = 0.8) -> dict:
    """Split windows in time order, matching floor(n * train_fraction) in R."""
    if not np.isfinite(train_fraction) or not 0 < train_fraction < 1:
        raise ValueError("train_fraction must be strictly between 0 and 1")
    n = len(dataset["y"])
    train_n = int(np.floor(n * train_fraction))
    if train_n < 1 or train_n >= n:
        raise ValueError("the split must leave at least one train and test row")
    return {
        "train": {name: values[:train_n] for name, values in dataset.items()},
        "test": {name: values[train_n:] for name, values in dataset.items()},
    }


def fit_price_scale(training_data: dict) -> tuple[float, float]:
    """Fit a [-1, 1] scale on training inputs and training targets only."""
    minimum = float(min(training_data["x"].min(), training_data["y"].min()))
    maximum = float(max(training_data["x"].max(), training_data["y"].max()))
    return minimum, maximum - minimum if maximum != minimum else 1.0


class LSTM(nn.Module):
    """Original architecture: one input, 32 hidden units and two LSTM layers."""

    def __init__(self) -> None:
        super().__init__()
        self.lstm = nn.LSTM(1, 32, 2, batch_first=True)
        self.linear = nn.Linear(32, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out, _ = self.lstm(x)  # PyTorch initializes hidden/cell states to zero.
        return self.linear(out[:, -1, :])


def train_lstm(
    prices: pd.DataFrame,
    symbol: str,
    epochs: int = 50,
    lookback: int = 20,
    train_fraction: float = 0.8,
    seed: int = 1,
) -> tuple[dict, pd.DataFrame]:
    """Train on CPU and return metrics and aligned held-out predictions."""
    if isinstance(epochs, bool) or not isinstance(epochs, int) or epochs < 1:
        raise ValueError("epochs must be a positive integer")
    if isinstance(seed, bool) or not isinstance(seed, int) or not 0 <= seed <= 2**32 - 1:
        raise ValueError("seed must be an integer between 0 and 4294967295")
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.set_num_threads(1)
    torch.use_deterministic_algorithms(True)
    split = split_lagged_data(make_lagged_data(prices, lookback), train_fraction)
    train, test = split["train"], split["test"]
    if len(train["y"]) < 2:
        raise ValueError("at least two training rows are required")
    minimum, span = fit_price_scale(train)

    def inputs(values: np.ndarray) -> torch.Tensor:
        scaled = 2.0 * (values - minimum) / span - 1.0
        return torch.from_numpy(scaled.astype(np.float32)).unsqueeze(-1)

    x_train, x_test = inputs(train["x"]), inputs(test["x"])
    y_train = inputs(train["y"])
    model = LSTM().cpu()
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    model.train()
    for _ in range(epochs):
        optimizer.zero_grad()
        loss = criterion(model(x_train), y_train)
        if not torch.isfinite(loss):
            raise ValueError(f"non-finite training loss for {symbol}")
        loss.backward()
        optimizer.step()
    model.eval()
    with torch.no_grad():
        scaled_prediction = model(x_test).squeeze(-1).numpy().astype(np.float64)
    predicted = (scaled_prediction + 1.0) * span / 2.0 + minimum
    if not np.isfinite(predicted).all() or predicted[0] == 0:
        raise ValueError(f"invalid predictions for {symbol}")
    errors = predicted - test["y"]
    dates = np.datetime_as_string(test["dates"], unit="D")
    metrics = {
        "symbol": symbol,
        "model": "LSTM",
        "rmse": float(np.sqrt(np.mean(errors**2))),
        "mae": float(np.mean(np.abs(errors))),
        "predicted_period_return": float(predicted[-1] / predicted[0] - 1.0),
        "test_start": dates[0],
        "test_end": dates[-1],
        "train_n": len(train["y"]),
        "test_n": len(test["y"]),
    }
    predictions = pd.DataFrame({
        "date": dates, "symbol": symbol, "model": "LSTM",
        "actual": test["y"], "predicted": predicted,
    }, columns=PREDICTION_COLUMNS)
    return metrics, predictions


def positive_integer(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return number


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1],
                        help="project folder containing data/stocks/")
    parser.add_argument("--output-dir", type=Path, default=None,
                        help="output directory (default: ROOT/outputs/models)")
    parser.add_argument("--epochs", type=positive_integer, default=50)
    parser.add_argument("--symbols", nargs="+", default=list(DEFAULT_SYMBOLS))
    parser.add_argument("--lookback", type=positive_integer, default=20)
    parser.add_argument("--train-fraction", type=float, default=0.8)
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args(argv)
    if not np.isfinite(args.train_fraction) or not 0 < args.train_fraction < 1:
        parser.error("--train-fraction must be strictly between 0 and 1")
    if not 0 <= args.seed <= 2**32 - 1:
        parser.error("--seed must be between 0 and 4294967295")
    if len(set(args.symbols)) != len(args.symbols) or any(
        not symbol.isdigit() for symbol in args.symbols
    ):
        parser.error("--symbols must be unique numeric stock codes")
    root = args.root.resolve()
    output_dir = args.output_dir.resolve() if args.output_dir else root / "outputs" / "models"
    files = [root / "data" / "stocks" / f"{symbol}_daily.xlsx" for symbol in args.symbols]
    missing = [str(path) for path in files if not path.is_file()]
    if missing:
        parser.error("stock workbooks not found: " + ", ".join(missing))
    metrics, predictions = [], []
    try:
        for symbol, path in zip(args.symbols, files):
            print(f"Training LSTM: {symbol}", flush=True)
            prices = pd.read_excel(path, usecols=["date", "close"], engine="openpyxl")
            metric, prediction = train_lstm(
                prices, symbol, args.epochs, args.lookback, args.train_fraction, args.seed
            )
            metrics.append(metric)
            predictions.append(prediction)
        output_dir.mkdir(parents=True, exist_ok=True)
        pd.DataFrame(metrics, columns=METRIC_COLUMNS).to_csv(
            output_dir / "lstm_metrics.csv", index=False
        )
        pd.concat(predictions, ignore_index=True).to_csv(
            output_dir / "lstm_predictions.csv", index=False
        )
    except (ImportError, OSError, ValueError) as error:
        print(f"LSTM training failed: {error}", file=sys.stderr)
        return 1
    print(f"Saved LSTM metrics and predictions to {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
