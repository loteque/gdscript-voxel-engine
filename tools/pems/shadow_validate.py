from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.cove.cove_v1 import decode, encode
from tools.cove.jcs_v1 import serialize_cove
from .human_export import render_human_markdown
from .import_current_handoff import ImportReport, import_handoff


@dataclass(frozen=True)
class ShadowObservation:
    label: str
    source_commit: str
    pems_sha256: str
    cove_jcs_sha256: str
    expanded_bytes: int
    compact_bytes: int
    record_count: int
    provisional_ids: tuple[str, ...]
    source_observation_id: str
    human_sha256: str


def _canonical_json(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def _sha(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def observe(handoff: Mapping[str, Any], *, label: str, source_commit: str) -> ShadowObservation:
    first: ImportReport = import_handoff(handoff, source_commit=source_commit)
    second: ImportReport = import_handoff(handoff, source_commit=source_commit)
    first_bytes = _canonical_json(first.document)
    if first_bytes != _canonical_json(second.document):
        raise ValueError("nondeterministic_import")

    cove = encode(first.document, profile="pems/1", serializer="jcs/1")
    compact = serialize_cove(cove)
    decoded = decode(json.loads(compact.decode("utf-8")), supported_profiles={"pems/1"})
    if decoded != first.document:
        raise ValueError("cove_jcs_round_trip_mismatch")

    human = render_human_markdown(first.document).encode("utf-8")
    return ShadowObservation(
        label=label,
        source_commit=source_commit,
        pems_sha256=_sha(first_bytes),
        cove_jcs_sha256=_sha(compact),
        expanded_bytes=len(first_bytes),
        compact_bytes=len(compact),
        record_count=len(first.document["records"]),
        provisional_ids=first.provisional_ids,
        source_observation_id=first.source_observation_id,
        human_sha256=_sha(human),
    )


def compare(previous: ShadowObservation, current: ShadowObservation) -> dict[str, Any]:
    previous_ids = set(previous.provisional_ids)
    current_ids = set(current.provisional_ids)
    unchanged_source = previous.source_commit == current.source_commit
    return {
        "from": previous.label,
        "to": current.label,
        "source_changed": not unchanged_source,
        "stable_candidate_ids": sorted(previous_ids & current_ids),
        "added_candidate_ids": sorted(current_ids - previous_ids),
        "removed_candidate_ids": sorted(previous_ids - current_ids),
        "source_observation_changed": previous.source_observation_id != current.source_observation_id,
        "canonical_bytes_stable_when_source_unchanged": (previous.cove_jcs_sha256 == current.cove_jcs_sha256) if unchanged_source else None,
        "human_export_stable_when_source_unchanged": (previous.human_sha256 == current.human_sha256) if unchanged_source else None,
        "expanded_byte_delta": current.expanded_bytes - previous.expanded_bytes,
        "compact_byte_delta": current.compact_bytes - previous.compact_bytes,
    }


def build_report(items: Sequence[tuple[str, str, Mapping[str, Any]]]) -> dict[str, Any]:
    observations = [observe(handoff, label=label, source_commit=commit) for label, commit, handoff in items]
    return {
        "phase": "pems-cove-phase7-shadow",
        "authority": "noncanonical_evidence",
        "observations": [observation.__dict__ for observation in observations],
        "transitions": [compare(a, b) for a, b in zip(observations, observations[1:])],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Produce noncanonical longitudinal PEMS/COVE shadow evidence.")
    parser.add_argument("snapshot", nargs="+", help="LABEL:COMMIT:PATH")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    items = []
    for spec in args.snapshot:
        label, commit, path = spec.split(":", 2)
        with Path(path).open("r", encoding="utf-8") as handle:
            handoff = json.load(handle)
        items.append((label, commit, handoff))
    report = build_report(items)
    text = json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
