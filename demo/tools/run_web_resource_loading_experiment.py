#!/usr/bin/env python3
"""Run the threaded Godot Web resource-loading microbenchmark in headless Chromium."""

from __future__ import annotations

import argparse
import http.server
import json
import pathlib
import socketserver
import subprocess
import sys
import threading
import time


RESULT_PREFIX = "WEB_RESOURCE_LOADING_EXPERIMENT_JSON="


class IsolationHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format: str, *args: object) -> None:
        pass


def serve(directory: pathlib.Path) -> tuple[socketserver.TCPServer, int]:
    handler = lambda *args, **kwargs: IsolationHandler(*args, directory=str(directory), **kwargs)
    server = socketserver.TCPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, int(server.server_address[1])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", default="build/web-resource-loading")
    parser.add_argument("--output", default="artifacts/performance/web-resource-loading-experiment.json")
    parser.add_argument("--timeout", type=int, default=240)
    args = parser.parse_args()

    build_dir = pathlib.Path(args.build_dir).resolve()
    output_path = pathlib.Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    chromium = "chromium"
    server, port = serve(build_dir)
    try:
        command = [
            chromium,
            "--headless=new",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            # GitHub-hosted runners have no usable GPU. Modern Chromium no longer
            # automatically falls back to SwiftShader for WebGL, so opt in explicitly
            # for this trusted local diagnostic export.
            "--use-gl=angle",
            "--use-angle=swiftshader-webgl",
            "--enable-unsafe-swiftshader",
            "--enable-features=SharedArrayBuffer",
            # Do not use Chromium virtual-time acceleration here. The experiment
            # measures real elapsed ResourceLoader behavior and worker progress.
            "--enable-logging=stderr",
            "--v=0",
            f"http://127.0.0.1:{port}/index.html",
        ]
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        deadline = time.monotonic() + args.timeout
        payload = None
        captured: list[str] = []
        assert process.stdout is not None
        while time.monotonic() < deadline:
            line = process.stdout.readline()
            if line:
                captured.append(line)
                print(line, end="")
                marker = line.find(RESULT_PREFIX)
                if marker >= 0:
                    candidate = line[marker + len(RESULT_PREFIX):].strip()
                    try:
                        payload = json.loads(candidate)
                    except json.JSONDecodeError:
                        pass
                    if payload is not None:
                        break
            elif process.poll() is not None:
                break
            else:
                time.sleep(0.05)

        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()

        if payload is None:
            sys.stderr.write("Web resource-loading experiment did not emit a result.\n")
            sys.stderr.write("".join(captured[-100:]))
            return 1
        output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"WEB_RESOURCE_LOADING_EXPERIMENT_OUTPUT={output_path}")
        return 0 if payload.get("success") else 1
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
