"""Small regression tests for LSTM preprocessing and deterministic CPU training.

Run from the project root with: python -m unittest discover -s tests -p test_lstm.py
"""

import importlib.util
from pathlib import Path
import unittest

import numpy as np
import pandas as pd


MODEL_PATH = Path(__file__).resolve().parents[1] / "scripts" / "train_lstm.py"
SPEC = importlib.util.spec_from_file_location("train_lstm", MODEL_PATH)
lstm = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(lstm)


def prices(count=37):
    return pd.DataFrame({
        "date": pd.date_range("2020-01-01", periods=count),
        "close": np.arange(1.0, count + 1.0),
    })


class LaggedDataTests(unittest.TestCase):
    def test_twenty_prior_closes_predict_next_date_after_sorting(self):
        data = lstm.make_lagged_data(prices(25).iloc[::-1])
        self.assertEqual(data["x"].shape, (5, 20))
        np.testing.assert_array_equal(data["x"][0], np.arange(1.0, 21.0))
        np.testing.assert_array_equal(data["x"][-1], np.arange(5.0, 25.0))
        np.testing.assert_array_equal(data["y"], np.arange(21.0, 26.0))
        self.assertEqual(data["dates"][0], np.datetime64("2020-01-21"))
        self.assertEqual(data["feature_end_dates"][0], np.datetime64("2020-01-20"))
        self.assertEqual(data["dates"][-1], np.datetime64("2020-01-25"))
        self.assertTrue(np.all(data["feature_end_dates"] < data["dates"]))

    def test_chronological_split_uses_floor_and_retains_all_rows(self):
        data = lstm.make_lagged_data(prices())  # 17 windows; floor(17 * .8) = 13.
        split = lstm.split_lagged_data(data)
        self.assertEqual(len(split["train"]["y"]), 13)
        self.assertEqual(len(split["test"]["y"]), 4)
        self.assertLess(split["train"]["dates"][-1], split["test"]["dates"][0])
        self.assertEqual(split["test"]["dates"][0], np.datetime64("2020-02-03"))
        for key in data:
            np.testing.assert_array_equal(
                np.concatenate([split["train"][key], split["test"][key]]), data[key]
            )

    def test_scale_includes_training_targets_and_excludes_holdout_extremes(self):
        stock = prices()
        stock.loc[33:, "close"] = [1000.0, 2000.0, 3000.0, 4000.0]
        split = lstm.split_lagged_data(lstm.make_lagged_data(stock))
        minimum, span = lstm.fit_price_scale(split["train"])
        self.assertEqual(minimum, 1.0)
        # The final training target is 33; the last training input is only 32.
        self.assertEqual(span, 32.0)
        self.assertEqual(split["test"]["y"][0], 1000.0)
        self.assertGreater(2.0 * (split["test"]["x"].max() - minimum) / span - 1.0, 1.0)

    def test_rejects_invalid_prices_and_lookback(self):
        valid = prices()
        invalid = {
            "missing close": valid.drop(columns="close"),
            "duplicate date": pd.concat([valid, valid.iloc[:1]]),
            "missing date": valid.assign(date=pd.NaT),
            "malformed date": valid.assign(date="invalid-date"),
            "missing close value": valid.assign(close=np.nan),
            "infinite close": valid.assign(close=np.inf),
            "zero close": valid.assign(close=0.0),
            "negative close": valid.assign(close=-1.0),
            "too few prices": valid.iloc[:20],
        }
        for label, stock in invalid.items():
            with self.subTest(case=label), self.assertRaises(ValueError):
                lstm.make_lagged_data(stock)
        for lookback in (0, -1, 1.5, True):
            with self.subTest(lookback=lookback), self.assertRaises(ValueError):
                lstm.make_lagged_data(valid, lookback)

    def test_rejects_invalid_or_empty_splits(self):
        data = lstm.make_lagged_data(prices())
        for fraction in (0.0, 1.0, -0.1, 1.1, np.nan, np.inf, 0.001):
            with self.subTest(fraction=fraction), self.assertRaises(ValueError):
                lstm.split_lagged_data(data, fraction)
        with self.assertRaises(ValueError):
            lstm.split_lagged_data(lstm.make_lagged_data(prices(21)))


class LSTMTrainingTests(unittest.TestCase):
    def test_seed_reproduces_predictions_and_metrics(self):
        stock = prices(40)
        metric_a, forecast_a = lstm.train_lstm(stock, "test", epochs=1, seed=7)
        # A different training call changes global RNG state before repeating seed 7.
        lstm.train_lstm(stock, "test", epochs=1, seed=19)
        metric_b, forecast_b = lstm.train_lstm(stock, "test", epochs=1, seed=7)
        self.assertEqual(metric_a, metric_b)
        pd.testing.assert_frame_equal(forecast_a, forecast_b, check_exact=True)
        np.testing.assert_array_equal(forecast_a["actual"], [37.0, 38.0, 39.0, 40.0])
        self.assertEqual(metric_a["test_start"], "2020-02-06")
        self.assertEqual(metric_a["test_end"], "2020-02-09")
        self.assertEqual(metric_a["train_n"], 16)
        self.assertEqual(metric_a["test_n"], 4)
        self.assertEqual(tuple(metric_a), lstm.METRIC_COLUMNS)
        self.assertEqual(tuple(forecast_a.columns), lstm.PREDICTION_COLUMNS)
        errors = forecast_a["predicted"].to_numpy() - forecast_a["actual"].to_numpy()
        self.assertAlmostEqual(metric_a["rmse"], float(np.sqrt(np.mean(errors ** 2))))
        self.assertAlmostEqual(metric_a["mae"], float(np.mean(np.abs(errors))))
        self.assertAlmostEqual(
            metric_a["predicted_period_return"],
            forecast_a["predicted"].iloc[-1] / forecast_a["predicted"].iloc[0] - 1.0,
        )

    def test_constant_prices_have_finite_scale_and_predictions(self):
        stock = prices(25).assign(close=5.0)
        train = lstm.split_lagged_data(lstm.make_lagged_data(stock))["train"]
        self.assertEqual(lstm.fit_price_scale(train), (5.0, 1.0))
        metrics, forecast = lstm.train_lstm(stock, "constant", epochs=1)
        self.assertTrue(np.isfinite(forecast["predicted"]).all())
        self.assertTrue(np.isfinite(metrics["rmse"]))

    def test_rejects_invalid_training_settings(self):
        for epochs in (0, -1, 1.5, True):
            with self.subTest(epochs=epochs), self.assertRaises(ValueError):
                lstm.train_lstm(prices(), "test", epochs=epochs)
        for seed in (-1, 2 ** 32, 1.5, True):
            with self.subTest(seed=seed), self.assertRaises(ValueError):
                lstm.train_lstm(prices(), "test", epochs=1, seed=seed)


if __name__ == "__main__":
    unittest.main()
