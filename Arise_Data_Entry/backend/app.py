from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict, List

from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CSV_HEADERS: List[str] = [
    "sleep_hours",
    "activity_minutes",
    "energy_level",
    "stress_level",
    "task_completion",
    "screen_time",
    "previous_day_mood",
    "mood_today",
]

CSV_PATH = Path(__file__).resolve().parents[2] / "dataset" / "data3.csv"


def ensure_csv_exists() -> None:
    CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    if CSV_PATH.exists():
        return

    with CSV_PATH.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=CSV_HEADERS)
        writer.writeheader()


def ensure_newline_before_append() -> None:
    if not CSV_PATH.exists() or CSV_PATH.stat().st_size == 0:
        return

    with CSV_PATH.open("rb") as csv_file:
        csv_file.seek(-1, 2)
        last_byte = csv_file.read(1)

    if last_byte not in (b"\n", b"\r"):
        with CSV_PATH.open("a", encoding="utf-8") as csv_file:
            csv_file.write("\n")


def parse_payload(payload: Dict[str, str]) -> Dict[str, float | int]:
    try:
        parsed = {
            "sleep_hours": float(payload["sleep_hours"]),
            "activity_minutes": int(payload["activity_minutes"]),
            "energy_level": int(payload["energy_level"]),
            "stress_level": int(payload["stress_level"]),
            "task_completion": int(payload["task_completion"]),
            "screen_time": float(payload["screen_time"]),
            "previous_day_mood": int(payload["previous_day_mood"]),
            "mood_today": int(payload["mood_today"]),
        }
    except KeyError as exc:
        raise ValueError(f"Missing field: {exc.args[0]}") from exc
    except (TypeError, ValueError) as exc:
        raise ValueError("All fields must contain valid numeric values") from exc

    if not 0 <= parsed["sleep_hours"] <= 24:
        raise ValueError("sleep_hours must be between 0 and 24")
    if not 0 <= parsed["activity_minutes"] <= 1440:
        raise ValueError("activity_minutes must be between 0 and 1440")
    if not 0 <= parsed["task_completion"] <= 100:
        raise ValueError("task_completion must be between 0 and 100")
    if not 0 <= parsed["screen_time"] <= 24:
        raise ValueError("screen_time must be between 0 and 24")

    for mood_field in ["energy_level", "stress_level", "previous_day_mood", "mood_today"]:
        if not 1 <= parsed[mood_field] <= 5:
            raise ValueError(f"{mood_field} must be between 1 and 5")

    return parsed


def normalize_row(row: Dict[str | None, str | List[str] | None]) -> Dict[str, str]:
    normalized: Dict[str, str] = {}
    for header in CSV_HEADERS:
        value = row.get(header, "")
        if isinstance(value, list):
            value = value[0] if value else ""
        normalized[header] = "" if value is None else str(value).strip()
    return normalized


@app.get("/api/health")
def health_check():
    return jsonify({"status": "ok"})


@app.get("/api/logs")
def get_logs():
    ensure_csv_exists()

    with CSV_PATH.open("r", newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        rows = [
            normalize_row(row)
            for row in reader
            if any(str(row.get(header, "") or "").strip() for header in CSV_HEADERS)
        ]

    return jsonify({"count": len(rows), "logs": rows[-20:]})


@app.post("/api/logs")
def add_log():
    ensure_csv_exists()
    ensure_newline_before_append()

    payload = request.get_json(silent=True) or {}

    try:
        parsed = parse_payload(payload)
    except ValueError as exc:
        return jsonify({"success": False, "error": str(exc)}), 400

    with CSV_PATH.open("a", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=CSV_HEADERS)
        writer.writerow(parsed)

    return jsonify({"success": True, "message": "Log added to data3.csv", "log": parsed}), 201


if __name__ == "__main__":
    app.run(debug=True)
