# PEMS Mapping and Reconciliation Evaluation

Date: 2026-08-15

## Purpose

Pressure-test the candidate-to-PEMS mapping contract against representative distiller records, provenance, derivation, general relations, duplicate reconciliation, and lifecycle replacement.

## Basis

Compared the current distiller protocol and admission contract against the frozen `pems/1` contract, including:

- closed PEMS record vocabulary;
- stable Steward-admitted semantic identity;
- `source` / immutable `source_observation` provenance chain;
- PEMS `derived_from`, `depends_on`, and `supersedes` relations;
- historical-preservation and supersession rules.

Evaluation cases are in `docs/distiller/evaluation/pems-mapping-cases.yaml`.

## Result

14/14 pressure cases produced a deterministic mapping disposition without coercing the candidate into a semantically different PEMS type.

### Lossless/native mappings identified

- consequential `uncertainty` -> `unresolved_item` when the candidate is actually an unresolved project item;
- validation-domain observations -> `validation` when the PEMS target and required fields are available;
- premise -> PEMS `derived_from`;
- `depends_on` -> PEMS `depends_on`;
- established, reviewed `supersedes` -> PEMS supersession relation/lifecycle handling;
- semantically equivalent candidates -> existing canonical identity.

### Review-required mappings identified

- project decisions;
- requirements/expectations inferred from claim-shaped distiller propositions;
- architecture/roadmap adjustments;
- supersession;
- mappings whose source identities survive but typed provenance roles cannot be represented in PEMS v1.

### PEMS v1 coverage gaps confirmed

No lossless native PEMS v1 representation exists for:

- generic assumptions;
- generic empirical observations as propositions;
- generic logical/evidentiary claims;
- `supports`;
- `contradicts`;
- typed provenance roles (`primary`, `corroborating`, `context`).

The evaluation intentionally treats these as `provisional_no_mapping` rather than abusing nearby PEMS kinds.

## Architectural Finding

The distiller is not a front-end syntax for PEMS. It is a generic reasoning graph upstream of a narrower project-memory ontology.

Therefore PEMS mapping is a semantic projection, not field renaming.

A total mapper against `pems/1` would necessarily be lossy. The correct v1 behavior is a partial mapper that can explicitly say "no canonical representation exists".

This also resolves a potential category error: PEMS `source_observation` is evidence capture, not the canonical representation of a distiller `observation` proposition.

## Provenance Finding

PEMS correctly requires claim provenance to terminate at immutable `source_observation` records rather than direct `source` references.

However, PEMS `observation_refs` flatten the distiller's provenance-role distinctions. The source identities can be retained, but primary/corroborating/context roles cannot currently round-trip through canonical `pems/1`.

No production PEMS schema change is proposed by this evaluation. The gap should be measured during shadow operation before revising the frozen contract.

## Reconciliation Finding

`temp_id` must remain transaction-local. Mapping first resolves every admitted record to a stable PEMS identity, constructs a complete temporary-to-canonical ID map, and only then rewrites premises and general relations.

Semantic equivalence must be Steward/admission identity reconciliation, not normalized-text matching. Material overlap, changed scope, changed authority, or conflicting state requires review.

## Decision

Adopt `docs/distiller/PEMS_MAPPING.md` as the Phase 4 mapping contract on the feature branch.

Do not implement a total automatic PEMS mapper. The next implementation should be a reconciliation planner that emits mapping outcomes and required reviews while leaving unsupported distiller meaning provisional.
