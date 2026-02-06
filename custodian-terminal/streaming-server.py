import os
import random
import time
from flask import Flask, Response, jsonify, request, send_from_directory

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command

APP_ROOT = os.path.dirname(os.path.abspath(__file__))

app = Flask(__name__, static_folder=None)
state = GameState()

BOOT_LINES = [
    "[ SYSTEM POWER: UNSTABLE ]",
    "[ AUXILIARY POWER ROUTED ]",
    "",
    "CUSTODIAN NODE — ONLINE",
    "STATUS: DEGRADED",
    "",
    "> Running integrity check…",
    "> Memory blocks: 12% intact",
    "> Long-range comms: OFFLINE",
    "> Archive uplink: OFFLINE",
    "> Automated defense grid: PARTIAL",
    "",
    "DIRECTIVE FOUND",
    "RETENTION MANDATE — ACTIVE",
    "",
    "WARNING:",
    "Issuing authority presumed defunct.",
    "",
    "Residual Authority accepted.",
    "",
    "Initializing Custodian interface…",
]


def _coerce_delay(raw, default=0.25):
    try:
        delay = float(raw)
    except (TypeError, ValueError):
        return default
    return max(0.05, min(delay, 2.0))


def _stream_boot(delay):
    for line in BOOT_LINES:
        payload = line
        if payload == "":
            yield "data:\n\n"
        else:
            yield f"data: {payload}\n\n"
        time.sleep(delay + random.random() * delay)
    yield "event: done\ndata: complete\n\n"


@app.route("/")
def index():
    return send_from_directory(APP_ROOT, "index.html")


@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory(APP_ROOT, filename)


@app.route("/stream/boot")
def stream_boot():
    delay = _coerce_delay(os.getenv("BOOT_DELAY", None))
    return Response(_stream_boot(delay), mimetype="text/event-stream")


@app.route("/command", methods=["POST"])
def command():
    payload = request.get_json(silent=True) or {}
    raw = payload.get("raw", "")
    result = process_command(state, raw)
    return jsonify({"ok": bool(result.ok), "lines": result.lines})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=7331, debug=True)
