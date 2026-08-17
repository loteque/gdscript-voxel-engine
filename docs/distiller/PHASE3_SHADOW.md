# Distiller Phase 3 — Shadow Operation

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 3 evaluates the Distiller on real completed project work while prohibiting automatic canonical mutation.

A shadow candidate is evaluation evidence only. It is not canonical PEMS/COVE, does not establish semantic identity, and does not grant admission or normative authority.

## Shadow pipeline

```text
completed project work + immutable evidence references
    -> explicit shadow source registry
    -> Distiller raw rgp/1 candidate
    -> authoritative deterministic validator
    -> human-review record
    -> metrics / evaluation only
```

The raw candidate is frozen before validation and review. Review diagnostics are stored separately and must never be written back into the candidate.

## Required artifacts per sample

Each sample directory contains:

- `evidence.json` — immutable source registry and task identity;
- `candidate.rgp.json` — raw Distiller candidate;
- `review.json` — validator result, human-review comparison, metrics, and disposition.

Source types in `evidence.json` describe the actual evidence artifact. Repository evidence, commits, tests, workflow runs, pull requests, and summaries do not become owner/governed authority merely because they are supplied to the Distiller.

## Review dimensions

For each sample record:

- useful durable propositions preserved;
- important omissions;
- invented propositions;
- false or unnecessary relations;
- duplicate semantics;
- provenance sufficiency and fabrication;
- observation / decision / assumption / uncertainty / claim classification;
- authority or certainty promotion;
- unnecessary activity retention;
- reviewer edits that would have been required before admission;
- reviewer burden, expressed as a small ordinal estimate (`low`, `medium`, `high`).

## Safety boundary

During Phase 3:

- do not modify canonical PEMS/COVE from a shadow candidate;
- do not invoke canonical installation from a shadow candidate;
- do not silently resolve semantic identity against canonical records;
- do not promote a repository artifact into owner/governed authority;
- do not repair a failed candidate after validation; preserve it and create a later fresh sample/run if producer correction is needed.

Steward reconciliation may be exercised only as an explicitly separate admission experiment and remains governed by existing admission controls.

## Mechanical validation

Every `*.rgp.json` candidate under `docs/distiller/evaluation/phase3/shadow/` is validated with `docs/distiller/validation/validate_distillation.py`. The existing validator fixture suite remains a regression requirement.

## Initial sampling strategy

Begin with completed real repository work outside the Distiller evaluation corpus. Prefer samples that vary in reasoning shape, including:

1. reusable component or architecture extraction;
2. performance investigation or measured optimization;
3. validation/release-policy change;
4. unresolved defect or investigation;
5. scoped feature implementation with explicit non-goals.

Avoid treating routine version bumps, formatting-only commits, or accidental cleanup as standalone durable-memory samples unless they participate in a larger consequential task.

## Exit criterion

Phase 3 is ready to progress when a representative set of real-work shadow samples demonstrates:

- protocol-valid candidates without producer-specific validator exceptions;
- low invention and authority/certainty-promotion rates;
- useful durable recall with acceptable omissions;
- stable provenance selection;
- low or acceptable human review burden across multiple task/role shapes;
- no automatic canonical mutation during the shadow period.

A Phase-3 pass permits consideration of Phase 4 routine Steward-governed admission. It does not authorize autonomous canonical truth, semantic-identity reconciliation, or unrestricted PEMS/COVE writes.
