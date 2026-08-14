#!/usr/bin/env python3
"""Give a mutable Godot Web preview a deployment-specific cache version.

Godot's generated PWA worker is intentionally cache-first. That is desirable for
immutable release builds, but a long-lived Integration Preview needs each deploy
to use a distinct cache namespace. Keep Godot's worker lifecycle unchanged and
only replace CACHE_VERSION with the current revision.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path


CACHE_VERSION_PATTERN = re.compile(r"const CACHE_VERSION = (['\"])(.*?)\1;")


def patch_service_worker(path: Path, revision: str) -> None:
    if not path.is_file():
        raise SystemExit(f"Service worker does not exist: {path}")

    revision = revision.strip()
    if not revision:
        raise SystemExit("Preview cache revision must not be empty.")

    text = path.read_text(encoding="utf-8")
    match = CACHE_VERSION_PATTERN.search(text)
    if match is None:
        raise SystemExit(
            "Refusing to patch an unrecognized Godot service worker; "
            "CACHE_VERSION was not found."
        )

    quote = match.group(1)
    replacement = f"const CACHE_VERSION = {quote}preview-{revision}{quote};"
    patched = text[: match.start()] + replacement + text[match.end() :]
    path.write_text(patched, encoding="utf-8")


def main() -> None:
    if len(sys.argv) not in (2, 3):
        raise SystemExit(
            "Usage: prepare_mutable_preview_service_worker.py "
            "<service-worker.js> [revision]"
        )

    revision = sys.argv[2] if len(sys.argv) == 3 else os.environ.get("GITHUB_SHA", "")
    patch_service_worker(Path(sys.argv[1]), revision)


if __name__ == "__main__":
    main()
