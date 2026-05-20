import json
from pathlib import Path
from typing import Tuple

from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__)

STATIC_DIR = Path(__file__).resolve().parent / "static"
TESTDATA_DIR = Path(__file__).resolve().parent.parent / "testdata" / "scenarios"


def load_scenario(scenario: str) -> Tuple[dict, int]:
    path = TESTDATA_DIR / f"{scenario}.json"
    if not path.exists():
        raise FileNotFoundError(f"Unknown scenario '{scenario}'. Expected file: {path}")

    payload = json.loads(path.read_text(encoding="utf-8"))
    http_status = payload.pop("http_status", 200)
    return payload, http_status


@app.route("/")
def checkout_demo():
    return send_from_directory(STATIC_DIR, "index.html")


@app.route("/payment", methods=["GET"])
def get_payment_methods():
    scenario = request.args.get("scenario", "happy_path")
    cell_number = request.args.get("CellNumber")
    if cell_number:
        app.logger.info("CellNumber=%s scenario=%s", cell_number, scenario)

    body, http_status = load_scenario(scenario)
    return jsonify(body), http_status


if __name__ == "__main__":
    app.run(port=8080, debug=True)
