# Reasoning Distiller Roadmap

## Goal

Develop a small, testable process that distills observable engineering work into provenance-backed symbolic reasoning records while allowing working agents to communicate concisely.

The roadmap intentionally progresses from prompt experiment to protocol to deterministic tooling to application. Do not build a service before the distillation contract is demonstrated to be useful and stable.

## Phase 0 — Corpus and Evaluation Cases

Establish a small evaluation corpus from completed voxel-engine work.

- Select several completed tasks containing meaningful decisions, evidence, assumptions, and uncertainty.
- Include at least one case with a rejected alternative, one validation-driven conclusion, one architectural decision, and one inconclusive investigation.
- Define expected durable information for each case by human review.
- Define failure examples: invented causality, invented alternatives, duplicated facts, loss of provenance, excessive retention, and promotion of agent interpretation to owner requirement.

Exit criterion: a repeatable corpus exists against which distillation quality can be judged.

## Phase 1 — Distiller Agent Prototype

Implement the distiller as a specialized agent instruction with a strict structured-output contract.

Initial candidate record types:

- observation
- decision
- assumption
- uncertainty

Initial relations:

- supports
- contradicts
- depends_on
- supersedes
- validated_by

Requirements:

- consume only observable task evidence and explicit outcomes;
- never claim or reconstruct hidden chain of thought;
- emit atomic candidate propositions rather than essays;
- attach provenance references where available;
- distinguish derived interpretation from governed project truth;
- omit low-value activity records;
- report unsupported relationships rather than guessing them.

Exit criterion: repeated runs over the evaluation corpus produce compact, useful candidate records with acceptably low invention and omission rates.

## Phase 2 — Distillation Protocol

Freeze the first experimental interchange format between working agents, the distiller, and memory tooling.

Define:

- evidence-bundle schema;
- candidate-record schema;
- relation schema;
- provenance requirements;
- epistemic/authority status;
- confidence representation if retained;
- rejection/error representation;
- versioning rules.

The protocol must remain independent of PEMS serialization and COVE encoding even when mappings exist.

Exit criterion: a distillation result can be validated without interpreting free-form prose.

## Phase 3 — Deterministic Validation Tooling

Move non-semantic responsibilities out of the agent.

Implement deterministic checks for:

- schema validity;
- reference integrity;
- allowed record and relation types;
- required provenance;
- malformed/self-referential relations;
- stable candidate identity where appropriate;
- duplicate candidate detection;
- complete-source repository-write safety for history-sensitive artifacts.

Do not automate semantic admission yet.

Exit criterion: invalid distillation output is rejected mechanically before it can reach project memory.

## Phase 4 — Admission Contract and PEMS Candidate Mapping

The admission boundary is now defined in `docs/distiller/ADMISSION.md`.

Validated distillation remains provisional until a separate admission step decides whether each connected candidate subgraph is rejected, retained provisionally, or admitted to canonical memory.

Admission must preserve provenance, premise structure, conflicts, uncertainty, assumptions, and historical identity. Structural validity is necessary but never sufficient for admission. Normative standing is resolved from external source chains rather than created by the admission mechanism.

Next establish:

- mapping from candidate records to stable PEMS identities;
- candidate-to-existing-record reconciliation;
- transactional premise and relation rewrites from `temp_id` to canonical IDs;
- conflict and supersession mapping;
- provisional/rejected operational metadata;
- initial review-required versus deterministically admissible policy classes.

Exit criterion: validated candidates can be reconciled and admitted into PEMS without weakening provenance, graph integrity, authority boundaries, or historical traceability.

## Phase 5 — Shadow Operation

Run the distiller after real project tasks without allowing it to mutate canonical memory automatically.

For each run:

- preserve the candidate output;
- compare it with the working agent's concise response;
- review what should and should not become durable memory;
- track false relations, missed records, duplicates, and unnecessary records;
- adjust vocabulary only when repeated evidence justifies it.

Exit criterion: the distiller routinely captures useful durable structure with low review burden.

## Phase 6 — Controlled Admission

Permit bounded automated admission only for record classes and provenance conditions shown to be reliable.

Keep higher-authority transitions explicit. In particular, an agent-derived interpretation must not silently become an owner requirement, project policy, or accepted architectural decision.

Exit criterion: admitted records remain trustworthy across multiple agent roles and tasks.

## Phase 7 — Orchestration and Productization

Only after the protocol and admission behavior are stable, decide whether orchestration should become a dedicated application/service.

Possible responsibilities:

- collect evidence bundles from agent/tool executions;
- invoke semantic distillation;
- run deterministic validation;
- submit candidates to reconciliation/admission;
- expose inspection and query interfaces;
- generate evaluation metrics and diagnostics.

Storage topology and conversational product integration remain deployment concerns, not semantic requirements.

Exit criterion: productization removes operational friction without changing the proven semantic contract.

## Deferred

Do not implement these until the narrow experiment demonstrates need:

- generalized cognition or chain-of-thought storage;
- large reasoning ontologies;
- automatic causal inference;
- fully autonomous architectural-decision admission;
- a dedicated database solely for the distiller;
- a long-running service;
- domain-specific voxel-engine reasoning types in the generic protocol.

## Evaluation Questions

At each phase ask:

1. Can another agent reconstruct why an important project decision exists without reading the original chat?
2. Are all durable claims traceable to observable evidence or explicit authority?
3. Does the representation distinguish fact, interpretation, assumption, and uncertainty?
4. Is the distiller inventing relationships that were not established?
5. Is it preserving too much low-value activity?
6. Does the symbolic record reduce the need for verbose conversational responses?
7. Would the representation remain useful outside this voxel-engine project?
