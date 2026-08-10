import json
import re
import sys
from pathlib import Path


VERSION_PATTERN = re.compile(r"^\d+\.\d+\.\d+$")


def version_key(value: str) -> tuple[int, int, int]:
    return tuple(map(int, value.split(".")))


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

    for version in versions:
        version_dir = archive / version
        if (version_dir / "index.html").is_file():
            terrain_releases.append({"version": version, "path": f"{version}/"})
        if (version_dir / "chunks" / "index.html").is_file():
            chunk_releases.append({"version": version, "path": f"{version}/chunks/"})

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
