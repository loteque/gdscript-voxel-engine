# Performance and Scaling Reports

This directory is the engineering record for reproducible performance, scalability, and stress-validation findings.

These reports are not product performance guarantees. They record observations from specific builds, environments, datasets, and validation procedures so later architecture and optimization decisions can be traced back to evidence.

## When to add a report

Add a report when a milestone is explicitly intended to answer a scaling or performance question, or when validation produces measurements that materially affect later architecture.

Typical examples include:

- large-dataset streaming validation;
- resource-loading investigations;
- scheduler/concurrency experiments;
- memory-pressure investigations;
- LOD comparisons;
- chunk-size or mesh-density comparisons;
- browser/platform-specific streaming investigations.

Ordinary correctness features do not need a performance report merely because they have tests.

## Naming

Prefer version-prefixed, descriptive filenames:

```text
0.13.0-large-single-lod-validation.md
0.14.0-resource-loading-analysis.md
0.15.0-lod-baseline.md
```

If a report is not tied to a release version, use a concise experiment name that remains stable after merge.

## Required structure

A useful report should distinguish evidence from interpretation. Include the following sections where applicable.

### Purpose

State the engineering question the experiment was intended to answer.

### Build and environment

Record enough provenance to reproduce or compare the observation:

- project version;
- relevant PR and merge commit;
- Godot version when important;
- platform and browser/runtime;
- hardware when known;
- whether the result came from CI, native runtime, Web runtime, or manual QA.

If an environment detail was not recorded, say so rather than guessing.

### Dataset and configuration

Record the inputs that materially affect the result, such as:

- total chunk count;
- chunk dimensions;
- sample spacing;
- LOD level;
- load and unload radii;
- scheduler start budget;
- maximum concurrent loads;
- traversal or residency behavior.

### Measured evidence

Record values actually observed by instrumentation, CI output, profiler output, or manual runtime diagnostics.

Do not mix estimates or architectural interpretations into this section without labeling them.

For approximate metrics, retain the qualifier. For example, `approximate resident mesh memory` is not equivalent to complete process memory usage.

### Engineering inference

Explain what the measurements suggest. Use language such as `suggests`, `indicates`, or `is consistent with` when the measurements do not isolate a cause directly.

Do not present inference as measurement.

### Decisions

Record decisions justified by the experiment, including decisions to avoid an optimization or refactor.

### Open questions and next experiments

List unresolved causes, hypotheses, and measurements that would reduce uncertainty in the next milestone.

## Baseline index

| Version | Report | Primary result |
| --- | --- | --- |
| 0.13.0 | [Large single-LOD streaming validation](0.13.0-large-single-lod-validation.md) | Correct 169-chunk single-LOD streaming established; mobile-Web resource-loading throughput emerged as the first material scaling constraint. |
| 0.14.0 | [Resource-loading analysis](0.14.0-resource-loading-analysis.md) | Native-headless loading saturates near concurrency 4 for the current fixture; background resource loading dominates measured latency, while the previously observed mobile-Web slowdown is not reproduced headlessly. |

## Reporting principles

Preserve raw observations even when a later change explains them. A failed or misleading validation run can still be useful evidence if the report clearly explains what changed and why the later run is the accepted baseline.

Do not optimize benchmark numbers by weakening engine contracts, changing the production path only for validation, or omitting inconvenient measurements.

Performance reports should support architecture decisions, not become a scoreboard.