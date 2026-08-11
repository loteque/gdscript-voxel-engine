#!/usr/bin/env python3

"""Classify whether a pull request requires a versioned release."""

from __future__ import annotations

import sys
from collections.abc import Iterable


def requires_versioned_release(paths: Iterable[str]) -> bool:
    """Return True when any changed path is outside documentation-only scope."""
    for raw_path in paths:
        path = raw_path.strip()
        if not path:
            continue
        if path.startswith("docs/") or path.endswith(".md"):
            continue
        return True
    return False


def main() -> int:
    print("true" if requires_versioned_release(sys.stdin) else "false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
