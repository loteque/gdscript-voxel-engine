from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any

from tools.pems.migration_seed import seed_migration
from tools.pems.pems_v1 import normalize_document, validate_schema, validate_semantics
from tools.cove.cove_v1 import encode, decode
from tools.cove.jcs_v1 import canonicalize
from tools.pems.human_export import render_human_markdown

PRIOR_COMMIT = "18ece6c5791da00ff5c14eb79172cf6d7fea5860"
CURRENT_COMMIT = "ff2718a00b3a267407beb446607ea6eeb664e66e"
HANDOFF_PATH = "docs/project-chat-handoff.json"


def git_json(commit: str, path: str) -> dict[str, Any]:
    raw = subprocess.check_output(["git", "show", f"{commit}:{path}"], text=True)
    value = json.loads(raw)
    if not isinstance(value, dict):
        raise RuntimeError("handoff root must be object")
    return value


def canonical_id(old: str) -> str:
    if old.startswith("import:"):
        return "pems:" + old[len("import:"):]
    if old.startswith("candidate:"):
        return "pems:candidate:" + old[len("candidate:"):]
    return old


def rewrite(value: Any, mapping: dict[str, str]) -> Any:
    if isinstance(value, str):
        return mapping.get(value, value)
    if isinstance(value, list):
        return [rewrite(v, mapping) for v in value]
    if isinstance(value, dict):
        return {k: rewrite(v, mapping) for k, v in value.items()}
    return value


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    prior = git_json(PRIOR_COMMIT, HANDOFF_PATH)
    current = git_json(CURRENT_COMMIT, HANDOFF_PATH)
    seed = seed_migration([(prior, PRIOR_COMMIT), (current, CURRENT_COMMIT)])

    ids = [r["id"] for r in seed.document["records"]] + [r["id"] for r in seed.document.get("relations", [])]
    mapping = {old: canonical_id(old) for old in ids}
    if len(set(mapping.values())) != len(mapping):
        raise RuntimeError("canonical identity collision")
    if any(new.startswith(("import:", "candidate:")) for new in mapping.values()):
        raise RuntimeError("provisional identity survived admission")

    admitted = normalize_document(rewrite(seed.document, mapping))
    schema = validate_schema(admitted)
    semantic = validate_semantics(admitted)
    if not schema.valid or not semantic.valid:
        raise RuntimeError(f"admitted corpus invalid: schema={schema.diagnostics} semantic={semantic.diagnostics}")

    compact = encode(admitted, profile="pems/1", serializer="jcs/1")
    compact_bytes = canonicalize(compact)
    if decode(json.loads(compact_bytes)) != admitted:
        raise RuntimeError("COVE/JCS semantic round trip failed")
    if canonicalize(encode(admitted, profile="pems/1", serializer="jcs/1")) != compact_bytes:
        raise RuntimeError("canonical bytes are nondeterministic")

    expanded_bytes = canonicalize(admitted)
    human = render_human_markdown(admitted).encode("utf-8")
    manifest = {
        "admission": "steward_confirmed_initial_corpus",
        "authority": "docs/project-chat-handoff.cove.json",
        "compatibility_derivative": "docs/project-chat-handoff.json",
        "source_snapshots": [PRIOR_COMMIT, CURRENT_COMMIT],
        "record_count": len(admitted["records"]),
        "relation_count": len(admitted.get("relations", [])),
        "admitted_identity_count": len(mapping),
        "retained_historical_ids": [mapping.get(x, x) for x in seed.retained_historical_ids],
        "source_observation_ids": [mapping.get(x, x) for x in seed.source_observation_ids],
        "expanded_sha256": sha256(expanded_bytes),
        "compact_sha256": sha256(compact_bytes),
        "human_sha256": sha256(human),
        "expanded_bytes": len(expanded_bytes),
        "compact_bytes": len(compact_bytes),
    }

    Path("docs/project-chat-handoff.cove.json").write_bytes(compact_bytes + b"\n")
    # Deterministic expanded PEMS compatibility/human-readable derivative.
    Path("docs/project-chat-handoff.json").write_bytes(expanded_bytes + b"\n")
    Path("docs/handoff/pems/phase8-admission-manifest.json").write_text(json.dumps({"manifest": manifest, "id_map": mapping}, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    Path("docs/handoff/pems/project-chat-handoff.md").write_bytes(human)
    Path("docs/handoff/pems/phase8-cutover-evidence.json").write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(manifest, sort_keys=True))


if __name__ == "__main__":
    main()
