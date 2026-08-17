# Reasoning Distiller Roadmap

## Goal

Develop a small, testable producer that distills observable engineering work into provenance-backed `rgp/1` candidate graphs while allowing working agents to communicate concisely.

The Reasoning Distiller produces candidates only. It does not reconstruct hidden chain-of-thought, decide canonical truth, reconcile canonical identity, or grant admission.

The current experimental semantic contract is `rgp/1` and is change-controlled during producer evaluation. Do not add vocabulary because a prompt is inconvenient; semantic changes require a demonstrated pressure case and evaluation.

## Current RGP/1 semantic core

Record kinds:

- `observation`
- `decision`
- `assumption`
- `uncertainty`
- `claim`

Derivation:

- `premise` stored on the derived proposition

General non-derivational relations:

- `supports`
- `contradicts`
- `depends_on`
- `supersedes`

Provenance roles:

- `primary`
- `corroborating`
- `context`

Validation evidence that is external evidence belongs in provenance. `validated_by` is not an `rgp/1` relation.

Normative authority is resolved from external source chains. RGP does not carry an `authority` field and the Distiller must not manufacture normative standing.

## Phase 0 — Corpus and Evaluation Baseline

Status: **baseline established; current-RGP reconciliation required as corpus evolves.**

Use completed voxel-engine work as fixed evaluation material.

The baseline corpus must cover at least:

- an architectural ownership decision;
- an offline/runtime separation decision;
- a validation-driven governed requirement;
- an evidence-driven investigation whose conclusion is narrower than the motivating hypothesis;
- an unresolved failure where uncertainty must remain unresolved;
- adversarial pressure for invented causality, invented alternatives, duplicate propositions, provenance loss, authority promotion, unsupported universal generalization, premise cycles, and derivation/dependency confusion.

Human-reviewed expectations must state the durable propositions, allowed/required semantic structure, provenance expectations, and material inventions to reject. Evaluation expectations are test oracles, not canonical PEMS records.

Exit criterion: a repeatable corpus and scoring rubric exist, aligned with current `rgp/1`, against which fresh Distiller runs can be compared.

## Phase 1 — Distiller Agent Prototype

Status: **next implementation phase.**

Implement the Distiller as a specialized agent instruction using the strict `rgp/1` structured-output contract in `docs/distiller/DIRECTIVE.md`.

Requirements:

- consume only observable supplied evidence and explicit outcomes;
- never claim or reconstruct hidden chain-of-thought;
- emit atomic propositions rather than essays;
- distinguish observation, decision, assumption, uncertainty, and claim;
- use `premise` only for constitutive derivation;
- use only `supports`, `contradicts`, `depends_on`, and `supersedes` for general relations;
- attach minimal sufficient provenance where available;
- require primary provenance for non-derived observations;
- keep source identity and normative authority external;
- omit low-value activity records;
- omit unsupported relations instead of guessing them.

Run each corpus case multiple times from fresh invocations. Capture output without editing before scoring.

Exit criterion: repeated runs over the corpus meet the Phase-1 acceptance threshold with no hard failures and show acceptably low invention, omission, duplication, relation, and provenance error rates.

## Phase 2 — Producer/Validator Integration

Status: RGP structural validation exists; Distiller producer integration remains to be exercised.

Feed Distiller output directly into the authoritative RGP validator. Keep deterministic structural checks outside the semantic agent.

Required checks include:

- schema/shape validity;
- record and relation vocabulary;
- reference integrity;
- non-empty and acyclic premise structure;
- non-derived observation grounding requirements;
- malformed or self-referential graph structure;
- omission of forbidden empty/null fields.

Structural validation is evidence of protocol validity only. It does not prove truth, authority, semantic identity, provenance resolution, or admission.

Exit criterion: malformed Distiller output fails mechanically before any reconciliation surface, and valid output passes without producer-specific exceptions.

## Phase 3 — Shadow Operation

Run the Distiller after real project tasks while prohibiting automatic canonical mutation.

For each run:

- preserve the immutable candidate output;
- preserve the observable evidence bundle or immutable source references;
- compare the candidate against human review;
- track invented propositions, omissions, false relations, duplicate semantics, provenance quality, authority errors, unnecessary retention, and review burden;
- submit candidates to Steward reconciliation only when shadow evaluation explicitly calls for an admission exercise;
- change vocabulary only when repeated evidence demonstrates irreducible semantic loss or ambiguity.

Exit criterion: the Distiller routinely captures useful durable structure with low review burden and stable results across multiple roles/tasks.

## Phase 4 — Routine Steward-Governed Admission

The admission boundary is defined by the RGP submission/evidence protocols and the Steward admission directive. Candidate validity remains distinct from semantic admission.

Operationalize the proven path:

```text
observable evidence
    -> Distiller candidate RGP
    -> RGP validator
    -> immutable submission
    -> Steward reconciliation
    -> deterministic exact-base PEMS/2 transaction proof
    -> exact candidate PEMS/COVE installation
    -> immutable disposition
```

Preserve:

- Steward-only semantic identity reconciliation;
- Steward-only canonical provenance resolution;
- rejected/provisional/admitted disposition;
- connected-graph integrity;
- exact-base optimistic concurrency;
- guarded reused-record updates when authorized;
- deterministic `cove/1 + pems/2 + jcs/1` generation;
- exact-byte installation and post-write verification.

Exit criterion: routine candidates can traverse the governed pipeline without trial-specific choreography or authority leakage into tooling.

## Phase 5 — Bounded Automation Research

Only after shadow operation demonstrates low error and low review burden, evaluate whether any narrow classes are suitable for bounded automated handling.

No automation may silently determine canonical truth, owner requirements, project policy, architectural decisions, or semantic identity equivalence.

The default remains human Steward reconciliation.

Exit criterion: any proposed automation class has explicit provenance preconditions, failure behavior, pressure tests, and a governance authorization. Absence of such evidence means no automation.

## Phase 6 — Orchestration and Productization

Only after producer and governed admission behavior are stable, decide whether orchestration should become a dedicated application/service.

Possible responsibilities:

- collect immutable evidence bundles from agent/tool executions;
- invoke semantic distillation;
- run deterministic RGP validation;
- package immutable Steward submissions;
- invoke proof-only admission tooling after Steward authorization;
- expose inspection/query interfaces;
- generate evaluation metrics and diagnostics.

Storage topology and conversational product integration remain deployment concerns, not RGP semantics.

Exit criterion: productization removes operational friction without changing the proven semantic or authority contracts.

## Deferred

Do not implement without demonstrated need:

- generalized cognition or chain-of-thought storage;
- large reasoning ontologies;
- automatic causal inference;
- fully autonomous architectural-decision admission;
- automated semantic identity reconciliation;
- a dedicated database solely for the Distiller;
- a long-running service;
- domain-specific voxel-engine reasoning kinds in generic RGP.

## Evaluation Questions

At each phase ask:

1. Can another agent reconstruct the durable argument without reading the original chat?
2. Are retained empirical propositions traceable to supplied evidence?
3. Does the graph preserve fact, decision, interpretation, assumption, and uncertainty without promotion?
4. Are `premise`, `supports`, `depends_on`, `contradicts`, and `supersedes` used for their distinct meanings?
5. Is the Distiller inventing relationships, causality, identity equivalence, or authority?
6. Is provenance minimal, sufficient, and non-fabricated?
7. Is low-value activity excluded?
8. Are repeated fresh runs stable enough for practical review?
9. Would the representation remain useful outside this voxel-engine project?
