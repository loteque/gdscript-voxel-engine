import json
import re
import sys
from pathlib import Path


VERSION_PATTERN = re.compile(r"^\d+\.\d+\.\d+$")
PREVIEW_ID = "integration"
PREVIEW_LABEL = "Integration Preview"
PREVIEW_ROOT = Path("preview") / PREVIEW_ID


def version_key(value: str) -> tuple[int, int, int]:
    return tuple(map(int, value.split(".")))


def release_entry(version: str, path: str) -> dict[str, str]:
    return {
        "id": version,
        "label": f"v{version}",
        "version": version,
        "type": "release",
        "path": path,
    }


def preview_entry(path: str) -> dict[str, str]:
    return {
        "id": PREVIEW_ID,
        "label": PREVIEW_LABEL,
        # Historical immutable pages still run the original selector, which
        # reads only `version`. Keep this compatibility field until those
        # archived pages are no longer expected to consume the live manifest.
        "version": PREVIEW_LABEL,
        "type": "preview",
        "path": path,
    }


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: build_demo_manifest.py <archive-root>")

    archive = Path(sys.argv[1])
    versions = sorted(
        [path.name for path in archive.iterdir() if path.is_dir() and VERSION_PATTERN.fullmatch(path.name)],
        key=version_key,
        reverse=True,
    )

    if not versions:
        raise SystemExit("No published semantic-version directories were found.")

    terrain_releases = []
    chunk_releases = []
    streaming_releases = []

    preview_dir = archive / PREVIEW_ROOT
    if (preview_dir / "index.html").is_file():
        terrain_releases.append(preview_entry(f"{PREVIEW_ROOT.as_posix()}/"))
    if (preview_dir / "chunks" / "index.html").is_file():
        chunk_releases.append(preview_entry(f"{PREVIEW_ROOT.as_posix()}/chunks/"))
    if (preview_dir / "streaming" / "index.html").is_file():
        streaming_releases.append(preview_entry(f"{PREVIEW_ROOT.as_posix()}/streaming/"))

    for version in versions:
        version_dir = archive / version
        if (version_dir / "index.html").is_file():
            terrain_releases.append(release_entry(version, f"{version}/"))
        if (version_dir / "chunks" / "index.html").is_file():
            chunk_releases.append(release_entry(version, f"{version}/chunks/"))
        if (version_dir / "streaming" / "index.html").is_file():
            streaming_releases.append(release_entry(version, f"{version}/streaming/"))

    demos = [
        {
            "key": "terrain",
            "name": "Terrain / Surface Nets Demo",
            "releases": terrain_releases,
        },
        {
            "key": "chunks",
            "name": "Chunk Validation Demo",
            "releases": chunk_releases,
        },
        {
            "key": "streaming",
            "name": "Chunk Streaming Demo",
            "releases": streaming_releases,
        },
    ]

    manifest = {
        "latest": versions[0],
        "versions": versions,
        "demos": [demo for demo in demos if demo["releases"]],
    }

    with (archive / "versions.json").open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
