from __future__ import annotations

from typing import Any, Mapping

from .pems_v1 import normalize_document


def render_human_markdown(document: Mapping[str, Any]) -> str:
    """Render normalized PEMS as a deterministic, searchable Markdown derivative."""
    normalized = normalize_document(document)
    records = normalized.get("records", [])
    relations = normalized.get("relations", [])
    lines = [
        "# PEMS Human Reconstruction",
        "",
        f"Semantic profile: `{normalized.get('semantic', '')}`",
        f"Root project: `{normalized.get('project_id', '')}`",
        "",
        "## Records",
        "",
    ]
    for record in records:
        lines.extend(
            [
                f"### `{record['id']}`",
                "",
                f"- kind: `{record['kind']}`",
                f"- lifecycle: `{record['lifecycle']}`",
                "- observations: " + ", ".join(f"`{item}`" for item in record.get("observation_refs", [])),
                "- data:",
            ]
        )
        for key in sorted(record.get("data", {}), key=lambda item: item.encode("utf-8")):
            lines.append(f"  - `{key}`: `{_display(record['data'][key])}`")
        lines.append("")

    lines.extend(["## Relations", ""])
    for relation in relations:
        lines.extend(
            [
                f"### `{relation['id']}`",
                "",
                f"- kind: `{relation['kind']}`",
                f"- lifecycle: `{relation['lifecycle']}`",
                f"- from: `{relation['from']}`",
                f"- to: `{relation['to']}`",
                "- observations: " + ", ".join(f"`{item}`" for item in relation.get("observation_refs", [])),
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def _display(value: Any) -> str:
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, list):
        return "[" + ", ".join(_display(item) for item in value) + "]"
    if isinstance(value, Mapping):
        parts = []
        for key in sorted(value, key=lambda item: str(item).encode("utf-8")):
            parts.append(f"{key}: {_display(value[key])}")
        return "{" + ", ".join(parts) + "}"
    return str(value).replace("`", "\\`").replace("\n", "\\n")
