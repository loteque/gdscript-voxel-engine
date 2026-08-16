# Reasoning Distiller Admission Contract

## Purpose

Admission is the boundary between validated distillation output and durable project memory.

Distillation proposes symbolic records. Validation proves structural conformance. Admission decides whether a validated candidate may enter canonical memory and in what state.

Admission must not convert agent output into project truth merely because it is well-formed.

## Lifecycle

```text
observable evidence
      ↓
distillation
      ↓
provisional candidate graph
      ↓
deterministic validation
      ↓
admission evaluation
      ↓
rejected | provisional | admitted
      ↓
canonical memory lifecycle
```

The distiller never emits `admitted` status. Admission is assigned only by the memory boundary.

## Admission Inputs

An admission evaluation receives:

- a structurally valid candidate graph;
- resolvable provenance references when the candidate relies on external grounding;
- existing canonical records relevant to reconciliation;
- project admission policy;
- source metadata required to determine source type or normative standing.

The admission layer must not infer meaning from source-ID spelling.

## Admission Outcomes

Each candidate record or relation receives exactly one admission outcome:

- `admitted`: accepted into canonical memory;
- `provisional`: retained as useful but not yet canonical;
- `rejected`: not admitted into canonical memory.

These are lifecycle outcomes, not proposition kinds and not fields in the distillation protocol.

A rejection does not mean the proposition is false. It means the candidate does not satisfy admission policy.

A provisional outcome does not mean the proposition is uncertain. It means canonical admission has not been granted.

## Core Invariants

### 1. Structural validity is necessary but insufficient

A candidate must pass deterministic distillation validation before admission evaluation.

Passing validation does not imply admission.

### 2. Admission does not establish truth

Admission records that a proposition belongs in canonical project memory under current policy.

Truth, empirical grounding, derivation, uncertainty, and normative standing remain represented by proposition kind, premise structure, provenance, source metadata, and graph relations.

### 3. Provenance must remain intact

Admission must preserve the provenance references supplied by the validated candidate.

Admission must not fabricate, replace, or silently broaden provenance.

If required provenance cannot be resolved, the candidate cannot be admitted as if the source were known.

### 4. Normative standing is derived from source chains

Owner or governed standing is never created by admission itself.

If canonical treatment depends on normative authority, the required standing must be recoverable through resolved provenance and, where applicable, premise traversal.

Implementation state, tests, summaries, chats, or agent interpretation do not become normative authority through admission.

### 5. Derived records retain their premise graph

Admission of a derived proposition must preserve its `premise` relationships.

A derived proposition must not be admitted while silently dropping premises that are required to explain its derivation.

If a premise is not canonical, the admission policy must either:

- admit the required premise in the same transaction;
- preserve a stable reference to an already admitted equivalent record; or
- keep the derived candidate provisional.

### 6. Conflicts are represented, not erased

A candidate that conflicts with canonical memory must not silently overwrite the conflicting record.

The admission layer must preserve the conflict explicitly, normally through `contradicts`, `supersedes`, or reconciliation against an equivalent record.

A newer source is not automatically a superseding source.

### 7. Uncertainty may be admitted

`uncertainty` records are legitimate durable memory when the unresolved condition is consequential.

Admission must not require uncertainties to be resolved before they may become canonical.

### 8. Assumptions may be admitted without becoming facts

`assumption` records may be canonical when they materially constrain ongoing work.

Admission preserves their kind. It must not promote them to observations or claims merely because they were admitted.

### 9. Admission is idempotent under equivalence

Re-admitting a semantically equivalent candidate with the same grounding should reconcile with the existing canonical record rather than create unnecessary duplication.

Exact equivalence rules belong to reconciliation tooling, but duplicate admission must not depend on free-form chat identity.

### 10. History is append-preserving

Supersession, contradiction, or later resolution must not rewrite earlier admitted reasoning as though it never existed.

Canonical memory may change which record is current, but historical propositions and their provenance remain traceable.

## Admission Policy Classes

The first implementation should support three policy classes.

### Deterministically admissible

Candidates whose canonical suitability can be decided from validated structure, resolved provenance, and explicit policy without semantic reinterpretation.

Examples may eventually include directly grounded repository observations or mechanically verifiable test results, but only after shadow evaluation demonstrates reliability.

### Review-required

Candidates whose admission depends on semantic judgment, conflict reconciliation, architectural interpretation, or normative effect.

Initial default: `decision`, `claim`, and any candidate that would alter current canonical understanding are review-required unless a narrower policy is explicitly proven safe.

### Non-admissible

Candidates that fail validation, require unavailable provenance, violate project policy, depend on unresolved dangling graph references, or cannot be reconciled safely.

Non-admissible candidates may still be retained outside canonical memory for evaluation diagnostics if policy permits.

## Record and Relation Atomicity

Admission is evaluated per record and relation, but graph dependencies constrain independent admission.

A relation cannot be admitted unless both endpoints resolve to canonical records in the resulting memory state.

A derived record cannot be admitted if its required premise references would become dangling.

Therefore an admission operation may need to be transactional over a connected candidate subgraph.

## Reconciliation

Before creating a canonical record, admission must check for an existing equivalent or materially overlapping record.

Possible reconciliation outcomes:

- map candidate to existing canonical identity;
- enrich existing record with additional permissible provenance;
- admit as a distinct compatible proposition;
- admit with an explicit conflict relation;
- admit as a superseding proposition when supersession is established;
- keep provisional for review;
- reject.

Reconciliation must not merge propositions merely because their wording is similar.

## Stable Identity

`temp_id` is local to distillation output and must not become the durable canonical identifier.

Admission or reconciliation assigns or resolves stable canonical identity.

All admitted premise and relation references must be rewritten from temporary candidate references to stable canonical references atomically.

## Authority-Sensitive Admission

A candidate may describe a project requirement, policy, accepted architecture, or owner decision only when the relevant normative standing is recoverable from source resolution.

Admission may preserve an agent-derived claim about a requirement, but must not transform that claim into an owner instruction.

Normative authority flows from sources; it is not bestowed by the admission mechanism.

## Rejection and Provisional Retention

Canonical memory should not require durable storage of every rejected candidate.

The admission system may retain rejection/provisional diagnostics separately for evaluation, including:

- candidate identity within the evaluation run;
- outcome;
- machine-readable reason code;
- references required to reproduce the decision.

These diagnostics are operational metadata and are not reasoning propositions.

## Initial Reason Codes

The admission implementation should use machine-readable reason codes rather than prose-only explanations. Initial candidates:

```text
accepted
needs_review
invalid_structure
unresolved_provenance
unresolved_premise
unresolved_relation_endpoint
duplicate_equivalent
conflict_requires_review
normative_authority_unresolved
policy_disallowed
```

The reason-code set is an operational contract and may evolve independently from the distillation ontology.

## Transaction Contract

An admission transaction must be atomic with respect to canonical graph integrity.

On success:

- every admitted record has stable identity;
- every admitted premise resolves;
- every admitted relation endpoint resolves;
- preserved provenance remains attached;
- canonical graph invariants hold.

On failure, no partial canonical graph mutation is committed.

## Initial Safety Policy

Until shadow operation demonstrates narrower safe automation:

- no automatic admission of normative project decisions;
- no automatic conflict resolution;
- no automatic supersession based only on recency;
- no automatic promotion of assumptions or uncertainties;
- no automatic rewriting of proposition kind;
- no admission with unresolved required provenance;
- no admission that creates dangling premise or relation references.

## Success Criterion

The admission boundary succeeds when validated distiller output can enter project memory without confusing structural validity with truth, agent interpretation with authority, provisional reasoning with canonical knowledge, or new evidence with silent historical replacement.
