import os
import sys
import signal
import subprocess
import time
from collections import deque

from flask import (
    Flask,
    Response,
    jsonify,
    render_template,
    request,
    stream_with_context,
)

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command
from game.simulations.world_state.terminal.result import CommandResult

APP_ROOT = os.path.dirname(os.path.abspath(__file__))
SIM_PATH = os.path.join(APP_ROOT, "sandbox_world.py")

app = Flask(__name__)

HISTORY_LIMIT = 2000
history = deque(maxlen=HISTORY_LIMIT)
current_process = None
command_state = GameState()


def _coerce_delay(raw, default=0.2):
    try:
        delay = float(raw)
    except (TypeError, ValueError):
        return default
    return max(0.05, min(delay, 2.0))


def _stream_world_state(delay):
    env = os.environ.copy()
    env["TICK_DELAY"] = str(delay)
    process = subprocess.Popen(
        [sys.executable, "-u", SIM_PATH],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=APP_ROOT,
        text=True,
        bufsize=1,
        env=env,
    )
    global current_process
    current_process = process
    start_time = time.time()
    print(f"[server] stream started delay={delay:.2f}s pid={process.pid}", flush=True)

    try:
        last_heartbeat = start_time
        line_count = 0
        for line in process.stdout:
            cleaned = line.rstrip("\n")
            history.append(cleaned)
            yield f"data: {cleaned}\n\n"
            line_count += 1
            now = time.time()
            if now - last_heartbeat >= 5:
                print(
                    f"[server] streaming lines={line_count} uptime={int(now - start_time)}s",
                    flush=True,
                )
                last_heartbeat = now
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
        current_process = None
        print("[server] stream closed", flush=True)


def _command_result_payload(result: CommandResult) -> dict:
    """Convert a CommandResult into the locked API payload."""

    return {"ok": result.ok, "lines": result.lines}


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/history")
def history_feed():
    return jsonify(list(history))


@app.route("/pause", methods=["POST"])
def pause():
    if current_process is None or current_process.poll() is not None:
        return jsonify({"status": "no-process"}), 409
    try:
        os.kill(current_process.pid, signal.SIGSTOP)
    except OSError:
        return jsonify({"status": "error"}), 500
    return jsonify({"status": "paused"})


@app.route("/resume", methods=["POST"])
def resume():
    if current_process is None or current_process.poll() is not None:
        return jsonify({"status": "no-process"}), 409
    try:
        os.kill(current_process.pid, signal.SIGCONT)
    except OSError:
        return jsonify({"status": "error"}), 500
    return jsonify({"status": "resumed"})


@app.route("/command", methods=["POST"])
def command():
    """Execute a terminal command and return a Phase 1 response."""

    payload = request.get_json(silent=True)
    raw = payload.get("raw") if isinstance(payload, dict) else None
    if not isinstance(raw, str) or not raw.strip():
        result = CommandResult(
            ok=False,
            lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."],
        )
        return jsonify(_command_result_payload(result))

    result = process_command(command_state, raw)
    return jsonify(_command_result_payload(result))


@app.route("/stream")
def stream():
    delay = _coerce_delay(request.args.get("delay"))
    print(f"[server] client connected delay={delay:.2f}s", flush=True)
    return Response(
        stream_with_context(_stream_world_state(delay)),
        mimetype="text/event-stream",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=7557, debug=True)
