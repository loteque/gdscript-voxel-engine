"""RFC 8785 / JCS deterministic UTF-8 serialization boundary for COVE.

This module owns byte serialization only. It deliberately contains no PEMS
semantics and does not alter COVE structural encoding rules.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
from typing import Any, Mapping

import rfc8785


SERIALIZER_VERSION = "jcs/1"
IMPLEMENTATION = "rfc8785"


@dataclass(frozen=True)
class JcsDiagnostic:
    code: str
    message: str


class JcsError(ValueError):
    def __init__(self, code: str, message: str):
        super().__init__(f"{code}: {message}")
        self.diagnostic = JcsDiagnostic(code=code, message=message)


def canonicalize(value: Any) -> bytes:
    """Return RFC 8785 canonical UTF-8 bytes for an I-JSON-compatible value."""
    try:
        return rfc8785.dumps(value)
    except (rfc8785.CanonicalizationError, OverflowError, ValueError, TypeError) as exc:
        raise JcsError("JCS_CANONICALIZATION_ERROR", str(exc)) from exc


def parse_canonical(data: bytes) -> Any:
    """Parse canonical JCS bytes and reject malformed or noncanonical input."""
    if not isinstance(data, bytes):
        raise JcsError("JCS_INVALID_BYTES", "input must be bytes")
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise JcsError("JCS_PARSE_ERROR", str(exc)) from exc
    if canonicalize(value) != data:
        raise JcsError("JCS_NONCANONICAL_INPUT", "input bytes are valid JSON but not canonical jcs/1")
    return value


def serialize_cove(artifact: Mapping[str, Any]) -> bytes:
    """Serialize a COVE envelope that explicitly declares serializer jcs/1."""
    if artifact.get("s") != SERIALIZER_VERSION:
        raise JcsError("JCS_SERIALIZER_MISMATCH", "COVE envelope must declare s='jcs/1'")
    return canonicalize(dict(artifact))


def measure_utf8_bytes(expanded: Any, cove_artifact: Mapping[str, Any]) -> dict[str, int]:
    """Measure actual canonical UTF-8 bytes, not Phase 3 structural characters."""
    return {
        "expanded_jcs_bytes": len(canonicalize(expanded)),
        "cove_jcs_bytes": len(serialize_cove(cove_artifact)),
    }
