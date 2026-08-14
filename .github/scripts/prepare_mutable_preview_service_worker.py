#!/usr/bin/env python3
"""Make a Godot PWA service worker safe for a mutable preview URL.

Godot's generated PWA worker is intentionally cache-first. That is desirable for
immutable release builds, but a long-lived Integration Preview can otherwise keep
an older HTML/JavaScript/PCK set alive after a new deployment. This patch adds a
second install/activate pair that immediately promotes the new worker, claims open
preview clients, and reloads them so the new worker serves the new cache version.
"""

from __future__ import annotations

import sys
from pathlib import Path


PATCH_MARKER = "// MUTABLE_PREVIEW_IMMEDIATE_UPDATE"
PATCH = r'''

// MUTABLE_PREVIEW_IMMEDIATE_UPDATE
// Integration Preview is mutable. Promote each newly deployed worker immediately
// so open clients cannot remain pinned to the previous Godot package cache.
self.addEventListener('install', (event) => {
	event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
	event.waitUntil(
		self.clients.claim()
			.then(() => self.clients.matchAll({ type: 'window' }))
			.then((clients) => Promise.all(clients.map((client) => client.navigate(client.url))))
	);
});
'''


def patch_service_worker(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"Service worker does not exist: {path}")

    text = path.read_text(encoding="utf-8")
    if PATCH_MARKER in text:
        return

    required_fragments = (
        "const CACHE_VERSION =",
        "self.addEventListener('install'",
        "self.addEventListener('activate'",
        "self.addEventListener(\n\t'fetch'",
    )
    missing = [fragment for fragment in required_fragments if fragment not in text]
    if missing:
        raise SystemExit(
            "Refusing to patch an unrecognized Godot service worker; missing: "
            + ", ".join(repr(fragment) for fragment in missing)
        )

    path.write_text(text.rstrip() + PATCH + "\n", encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: prepare_mutable_preview_service_worker.py <service-worker.js>")
    patch_service_worker(Path(sys.argv[1]))


if __name__ == "__main__":
    main()
