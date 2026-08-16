# Reasoning Distiller Roadmap

## Goal

Develop a small, testable process that distills observable work into provenance-backed **Reasoning Graph Protocol (RGP)** graphs while allowing working agents to communicate concisely.

RGP is domain-independent. The Reasoning Distiller is one producer of candidate RGP graphs; PEMS is one application memory system that may consume them.

The roadmap intentionally progresses from prompt experiment to protocol to deterministic tooling to application. Do not build a service before the distillation contract is demonstrated to be useful and stable.

## Phase 0 — Corpus and Evaluation Cases

Establish a small evaluation corpus from completed work.

- Select tasks containing meaningful decisions, evidence, assumptions, claims, and uncertainty.
- Include rejected alternatives, validation-driven conclusions, decisions, and inconclusive investigations.
- Define expected durable information by human review.
- Define failure examples: invented causality, invented alternatives, duplicated facts, loss of provenance, excessive retention, and promotion of interpretation to authority.

Exit criterion: a repeatable corpus exists against which distillation quality can be judged.

## Phase 1 — Distiller Agent Prototype

Implement the distiller as a specialized agent instruction with a strict structured-output contract.

The vocabulary evolved through evaluation and is now captured normatively in `docs/distiller/RGP.md` and `docs/distiller/DIRECTIVE.md`.

Requirements:

- consume only observable task evidence and explicit outcomes;
- never claim or reconstruct hidden chain of thought;
- emit atomic candidate propositions rather than essays;
- attach provenance references where available;
- preserve derivation structurally through premises;
- distinguish assumptions, uncertainty, observations, claims, and decisions;
- omit low-value activity records;
- report only established relationships.

Exit criterion: repeated runs over the evaluation corpus produce compact, useful candidate RGP graphs with acceptably low invention and omission rates.

## Phase 2 — Reasoning Graph Protocol

The experimental interchange format is now named the **Reasoning Graph Protocol (RGP)**.

RGP defines:

- proposition kinds;
- atomic statements;
- premise-based derivation;
- general proposition relations;
- typed provenance roles;
- external source resolution semantics;
- structural invariants.

RGP remains independent of PEMS serialization and COVE encoding even when mappings exist.

Exit criterion: an RGP graph can be validated without interpreting free-form prose.

## Phase 3 — Deterministic Validation Tooling

Move non-semantic responsibilities out of the agent.

Implement deterministic checks for:

- schema validity;
- reference integrity;
- allowed record and relation types;
- required provenance;
- premise acyclicity and self-reference;
- malformed relations;
- duplicate candidate detection;
- complete-source repository-write safety for history-sensitive artifacts.

Do not automate semantic admission merely because a graph is structurally valid.

Exit criterion: invalid RGP output is rejected mechanically before it can reach application memory.

## Phase 4 — Admission Contract and PEMS Integration

The admission boundary is defined in `docs/distiller/ADMISSION.md`.

Validated RGP output remains provisional until a separate admission step decides whether each connected candidate subgraph is rejected, retained provisionally, or admitted to canonical memory.

`docs/distiller/PEMS_MAPPING.md` demonstrates that PEMS v1 can preserve only a partial projection of RGP. Unsupported RGP semantics remain provisional rather than being coerced into incorrect PEMS types.

`docs/distiller/PEMS_RGP_PROPOSAL.md` proposes native RGP semantic support in a future versioned PEMS revision while keeping `pems/1` frozen.

Current integration work includes:

- candidate-to-existing-record reconciliation;
- stable canonical identity;
- transactional premise and relation rewrites from `temp_id` to canonical IDs;
- conflict and supersession mapping;
- provisional/rejected operational metadata;
- review-required versus deterministically admissible policy classes;
- architectural evaluation of native RGP support in PEMS.

Exit criterion: validated RGP candidates can be reconciled and admitted without weakening provenance, graph integrity, authority boundaries, or historical traceability.

## Phase 5 — Shadow Operation

Run the distiller after real tasks without allowing it to mutate canonical memory automatically.

For each run:

- preserve the candidate RGP output;
- compare it with the working agent's concise response;
- review what should and should not become durable memory;
- track false relations, missed records, duplicates, and unnecessary records;
- adjust vocabulary only when repeated evidence justifies it.

Exit criterion: the distiller routinely captures useful durable structure with low review burden.

## Phase 6 — Controlled Admission

Permit bounded automated admission only for record classes and provenance conditions shown to be reliable.

Keep authority-sensitive transitions explicit. Agent-derived interpretation must not silently become owner instruction, project policy, or accepted architecture.

Exit criterion: admitted records remain trustworthy across multiple agents, domains, and tasks.

## Phase 7 — Orchestration and Productization

Only after RGP and admission behavior are stable, decide whether orchestration should become a dedicated application/service.

Possible responsibilities:

- collect evidence bundles from agent/tool executions;
- invoke semantic distillation;
- run deterministic RGP validation;
- submit candidates to reconciliation/admission;
- expose inspection and query interfaces;
- generate evaluation metrics and diagnostics.

Storage topology and conversational product integration remain deployment concerns, not RGP semantic requirements.

Exit criterion: productization removes operational friction without changing the proven semantic contract.

## Deferred

Do not implement these until demonstrated need exists:

- hidden chain-of-thought storage;
- large reasoning ontologies;
- automatic causal inference;
- fully autonomous authority-sensitive admission;
- a dedicated database solely for the distiller;
- a long-running service;
- domain-specific concepts in the generic RGP core.

## Evaluation Questions

At each phase ask:

1. Can another consumer reconstruct why important knowledge exists without reading the original conversation?
2. Are durable propositions traceable to observable evidence or explicit sources where required?
3. Does RGP preserve observation, interpretation, assumption, decision, and uncertainty distinctly?
4. Is the distiller inventing relationships that were not established?
5. Is it preserving too much low-value activity?
6. Does the symbolic record reduce the need for verbose conversational responses?
7. Does the representation remain useful outside this project and outside engineering?