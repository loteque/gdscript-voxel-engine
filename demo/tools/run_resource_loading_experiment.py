#!/usr/bin/env python3
"""Run the controlled native-headless resource-loading experiment matrix.

Each repetition launches a fresh Godot process so Godot's in-process ResourceLoader
cache cannot carry results across cases. The operating-system filesystem cache is
intentionally reported as uncontrolled rather than mislabelled as cold.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import subprocess
from pathlib import Path
from typing import Any, Iterable


DEFAULT_CONCURRENCY = (1, 2, 4, 8)
DEFAULT_REPETITIONS = 3


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output-dir", default="artifacts/performance/resource-loading-analysis")
    parser.add_argument("--repetitions", type=int, default=DEFAULT_REPETITIONS)
    parser.add_argument("--concurrency", type=int, nargs="+", default=list(DEFAULT_CONCURRENCY))
    return parser.parse_args()


def run_case(godot: str, output_dir: Path, concurrency: int, repetition: int) -> dict[str, Any]:
    case_path = output_dir / f"concurrency-{concurrency}-rep-{repetition}.json"
    command = [
        godot,
        "--headless",
        "--path",
        ".",
        "--script",
        "demo/tools/RunResourceLoadingExperiment.gd",
        "--",
        f"--concurrency={concurrency}",
        f"--repetition={repetition}",
        f"--output={case_path.as_posix()}",
    ]
    completed = subprocess.run(command, check=False, text=True, capture_output=True)
    print(completed.stdout, end="")
    if completed.stderr:
        print(completed.stderr, end="")
    if completed.returncode != 0:
        raise RuntimeError(
            f"Experiment failed for concurrency={concurrency}, repetition={repetition} "
            f"with exit code {completed.returncode}."
        )
    return json.loads(case_path.read_text(encoding="utf-8"))


def pearson(values_x: Iterable[float], values_y: Iterable[float]) -> float | None:
    pairs = [(float(x), float(y)) for x, y in zip(values_x, values_y)]
    if len(pairs) < 2:
        return None
    xs, ys = zip(*pairs)
    mean_x = statistics.fmean(xs)
    mean_y = statistics.fmean(ys)
    denominator_x = math.sqrt(sum((x - mean_x) ** 2 for x in xs))
    denominator_y = math.sqrt(sum((y - mean_y) ** 2 for y in ys))
    if denominator_x == 0.0 or denominator_y == 0.0:
        return None
    return sum((x - mean_x) * (y - mean_y) for x, y in pairs) / (denominator_x * denominator_y)


def summarize_group(cases: list[dict[str, Any]]) -> dict[str, Any]:
    run_durations = [float(case["measured"]["run_duration_msec"]) for case in cases]
    metrics = [case["measured"]["metrics"] for case in cases]
    observations = [observation for case in cases for observation in case["measured"]["load_observations"]]

    aggregate_latencies = [float(value["aggregate_latency_msec"]) for value in observations]
    background_waits = [float(value["background_wait_msec"]) for value in observations]
    residency_completions = [float(value["residency_completion_msec"]) for value in observations]
    sizes = [float(value.get("serialized_size_bytes", 0)) for value in observations]
    vertices = [float(value.get("mesh_vertex_count", 0)) for value in observations]
    indices = [float(value.get("mesh_index_count", 0)) for value in observations]

    return {
        "repetitions": len(cases),
        "run_duration_msec": stats(run_durations),
        "average_load_latency_msec": stats([float(value["average_load_latency_msec"]) for value in metrics]),
        "average_background_wait_msec": stats([float(value["average_background_wait_msec"]) for value in metrics]),
        "average_residency_completion_msec": stats(
            [float(value["average_residency_completion_msec"]) for value in metrics]
        ),
        "completed_load_count": stats([float(value["completed_load_count"]) for value in metrics]),
        "unload_count": stats([float(value["unload_count"]) for value in metrics]),
        "peak_resident_count": stats([float(value["peak_resident_count"]) for value in metrics]),
        "peak_queued_count": stats([float(case["measured"]["peak_queued_count"]) for case in cases]),
        "peak_loading_count": stats([float(case["measured"]["peak_loading_count"]) for case in cases]),
        "peak_process_gap_msec": stats([float(case["measured"]["peak_process_gap_msec"]) for case in cases]),
        "observation_count": len(observations),
        "per_load_latency_msec": stats(aggregate_latencies),
        "per_load_background_wait_msec": stats(background_waits),
        "per_load_residency_completion_msec": stats(residency_completions),
        "correlation": {
            "serialized_size_vs_aggregate_latency": pearson(sizes, aggregate_latencies),
            "vertex_count_vs_aggregate_latency": pearson(vertices, aggregate_latencies),
            "index_count_vs_aggregate_latency": pearson(indices, aggregate_latencies),
            "serialized_size_vs_background_wait": pearson(sizes, background_waits),
        },
    }


def stats(values: list[float]) -> dict[str, float] | None:
    if not values:
        return None
    ordered = sorted(values)
    return {
        "min": min(values),
        "median": statistics.median(values),
        "mean": statistics.fmean(values),
        "max": max(values),
        "p95": percentile(ordered, 0.95),
    }


def percentile(ordered: list[float], fraction: float) -> float:
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def build_markdown(aggregate: dict[str, Any]) -> str:
    lines = [
        "# Headless Resource-Loading Experiment",
        "",
        "This artifact is an automated native-headless observation of the production streaming path.",
        "It is not a GPU or browser rendering benchmark.",
        "",
        "| Concurrent loads | Median run (ms) | Mean load latency (ms) | Mean background wait (ms) | Mean residency completion (ms) | Peak loading |",
        "| ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for concurrency in sorted(aggregate["groups"], key=int):
        group = aggregate["groups"][concurrency]
        lines.append(
            "| {c} | {run:.2f} | {load:.2f} | {background:.2f} | {residency:.2f} | {loading:.1f} |".format(
                c=concurrency,
                run=group["run_duration_msec"]["median"],
                load=group["average_load_latency_msec"]["mean"],
                background=group["average_background_wait_msec"]["mean"],
                residency=group["average_residency_completion_msec"]["mean"],
                loading=group["peak_loading_count"]["max"],
            )
        )
    lines.extend(
        [
            "",
            "## Interpretation guardrails",
            "",
            "- Headless mode exercises threaded ResourceLoader execution and normal MeshInstance3D residency creation.",
            "- Headless mode does not establish real GPU draw cost, browser scheduling behavior, or mobile-Web frame time.",
            "- Process-gap measurements contain CI scheduling noise and must not be presented as rendered frame times.",
            "- Each repetition uses a fresh Godot process; operating-system filesystem cache state remains uncontrolled.",
            "- ChunkStreamer completion timing remains polling-cadence observed.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    cases: list[dict[str, Any]] = []
    for concurrency in args.concurrency:
        for repetition in range(1, args.repetitions + 1):
            cases.append(run_case(args.godot, output_dir, concurrency, repetition))

    groups: dict[str, list[dict[str, Any]]] = {}
    for case in cases:
        key = str(case["configuration"]["max_concurrent_loads"])
        groups.setdefault(key, []).append(case)

    aggregate = {
        "schema_version": 1,
        "experiment": "resource-loading-analysis-headless-matrix",
        "case_count": len(cases),
        "concurrency_levels": args.concurrency,
        "repetitions_per_level": args.repetitions,
        "groups": {key: summarize_group(group) for key, group in groups.items()},
        "environment": cases[0]["environment"] if cases else {},
        "configuration": cases[0]["configuration"] if cases else {},
        "limitations": cases[0]["limitations"] if cases else [],
    }

    (output_dir / "aggregate.json").write_text(json.dumps(aggregate, indent=2), encoding="utf-8")
    (output_dir / "summary.md").write_text(build_markdown(aggregate), encoding="utf-8")
    print(f"RESOURCE_LOADING_EXPERIMENT_AGGREGATE={output_dir / 'aggregate.json'}")


if __name__ == "__main__":
    main()
