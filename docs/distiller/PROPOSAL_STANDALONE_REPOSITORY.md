# Proposal: Extract the Reasoning Distiller into a Standalone Repository

Status: **Proposed — Steward and Architect review required**
Date: 2026-08-17
Source project: `loteque/gdscript-voxel-engine`
Source branch: `project-chat-handoff`

## Decision requested

Approve extraction of the Reasoning Distiller system from the voxel-engine repository into a dedicated, project-independent repository before continuing Phase 6 production productization.

The voxel engine would remain the first reference consumer and its completed work would remain a fixed proving and regression corpus for the standalone system.

## Why now

The Distiller has progressed beyond an experiment local to voxel-engine development. The current work includes a reasoning graph protocol, deterministic validation, repeated-run evaluation, shadow operation, Steward-governed semantic reconciliation, exact-base admission proof, exact-byte installation, guarded execution automation, and production-hardening requirements.

Phase 6 introduces stable invocation, evidence-envelope, adapter, lifecycle, compatibility, permission, recovery, and production interfaces. Defining those interfaces while the system remains structurally embedded in one consuming repository risks encoding voxel-engine-specific assumptions into otherwise generic contracts.

Repository extraction now creates a clean boundary before those production interfaces are frozen.

## Proposed architecture

The standalone repository owns the generic system:

```text
observable evidence
    -> evidence envelope
    -> Distiller
    -> rgp/1 candidate
    -> deterministic validator
    -> immutable submission
    -> Steward semantic reconciliation
    -> deterministic proof/executor
    -> consuming project's canonical memory
```

A consuming project owns project-specific evidence adapters, canonical state, authority assignments, and integration configuration.

The Distiller remains a **candidate producer only**. It receives no semantic-reconciliation or admission authority.

The **Steward** remains the authority responsible for semantic reconciliation and admission decisions. The generic architecture defines that role; each consuming project determines who or what is authorized to occupy it.

## Proposed standalone layout

```text
reasoning-distiller/
    protocol/
        rgp/
    distiller/
    validator/
    reconciliation/
    admission/
    schemas/
    orchestration/
    evaluation/
        corpus/
            voxel-engine/
        expected/
        scoring/
    fixtures/
    tests/
    docs/
    examples/
```

The exact repository name and packaging layout may be adjusted during implementation without changing the architectural decision.

## What moves

Move or reconstruct as generic assets:

- the `rgp/1` semantic contract;
- Distiller directive/invocation behavior;
- deterministic RGP validator and fixtures;
- evaluation/scoring framework;
- generic submission contracts;
- generic Steward reconciliation-plan/transaction contracts;
- deterministic proof and guarded execution mechanisms that are not project-specific;
- authority-boundary documentation;
- production orchestration contracts and tests;
- Phase 0–5 evaluation evidence needed to demonstrate system evolution and parity.

Move the voxel-engine Distiller cases into an explicitly named reference corpus such as `evaluation/corpus/voxel-engine/`. Preserve fixed evidence and expected results so they remain useful for regression testing.

## What stays with the voxel engine

Keep project-owned state and integration concerns in `gdscript-voxel-engine`:

- canonical voxel-engine PEMS/COVE state;
- voxel-engine-specific evidence adapters/configuration;
- project-specific Steward transactions, dispositions, and authority assignments where they are part of the voxel-engine historical record;
- integration configuration selecting a released Distiller/protocol version;
- project-specific operational policy not required by the generic system.

After extraction parity is established, duplicated generic implementation should be removed from the voxel-engine repository as its integration migrates to the standalone release.

## Extraction invariants

Extraction must not silently change semantics.

Before moving behavior forward:

1. record the source repository, branch, and exact extraction commit;
2. create an extraction manifest containing source paths and blob hashes;
3. classify each extracted artifact as generic, reference-corpus, or project-owned;
4. preserve raw Phase 0–5 evaluation candidates/evidence without post-hoc semantic editing;
5. run the existing structural, evaluation, proof, and authority-boundary regression suites in the standalone repository;
6. establish an extraction-parity baseline before changing production behavior.

The required invariant is:

> Repository extraction alone does not change Distiller semantics or the authority boundary.

## Generalization policy

Extraction is not authorization for speculative abstraction.

Keep `rgp/1` stable during extraction. Do not add vocabulary, a plugin framework, database, long-running service, automatic causal inference, or automated semantic-identity reconciliation merely to make the repository appear generic.

The voxel-engine corpus demonstrates multiple reasoning shapes inside one engineering domain. A second independent project corpus should be required before treating untested cross-domain assumptions as established generic requirements.

## Phase 6 restructuring

Make repository extraction the first Phase-6 checkpoint:

- **6.0 — Repository extraction and behavioral parity**
- **6.1 — Stable production Distiller invocation contract**
- **6.2 — Generic evidence-envelope contract**
- **6.3 — Project adapter interface**
- **6.4 — Submission orchestration**
- **6.5 — Failure recovery and idempotency**
- **6.6 — Lifecycle state model**
- **6.7 — Permission and authority hardening**
- **6.8 — Contract/version compatibility**
- **6.9 — Operational metrics and SLOs**
- **6.10 — Production acceptance corpus**
- **6.11 — Production release**

Phase 0–5 remain completed validation history and should not be reinterpreted as incomplete merely because their generic implementation moves repositories.

## Initial integration strategy

Do not simultaneously extract the system and redesign the voxel-engine integration.

Recommended order:

1. create the standalone repository;
2. extract generic assets and the immutable voxel-engine reference corpus;
3. prove behavioral parity in the standalone repository;
4. establish an initial standalone baseline/release;
5. continue Phase 6 against the standalone architecture;
6. reconnect voxel-engine as the first production consumer through the stable interfaces;
7. add a second project corpus as the first cross-project generalization pressure test.

This separates extraction failures from integration/interface failures.

## Authority and safety boundary

The following invariants remain mandatory after extraction:

- Distiller produces candidates only;
- Distiller does not determine canonical semantic identity;
- Distiller does not reconcile or admit its own output;
- Steward owns semantic reconciliation and admission authority;
- deterministic tooling may validate and execute an already-authorized reconciliation plan but does not acquire semantic authority by doing so;
- canonical writes remain exact-base, guarded, auditable, and exact-byte verified;
- uncertainty must not be promoted to certainty merely through distillation or execution.

## Risks and mitigations

### Premature generalization

**Risk:** generic interfaces encode abstractions that have not been demonstrated.

**Mitigation:** preserve `rgp/1`, extract behavior first, require demonstrated pressure before semantic expansion, and add a second project corpus.

### Regression during extraction

**Risk:** file movement or refactoring subtly changes producer/validator/admission behavior.

**Mitigation:** extraction manifest, immutable reference corpus, full parity suite, and a named extraction-parity baseline before feature work resumes.

### Split-brain implementations

**Risk:** voxel-engine and standalone copies evolve independently.

**Mitigation:** after parity/release, make voxel-engine consume a versioned standalone release and remove duplicated generic implementation.

### Authority leakage

**Risk:** productization accidentally gives the Distiller or executor reconciliation authority.

**Mitigation:** retain the explicit Distiller → Steward → deterministic executor separation as a tested production invariant.

### Loss of proving evidence

**Risk:** extracting the generic system severs it from the evidence that established its behavior.

**Mitigation:** preserve voxel-engine work as a versioned reference corpus with immutable source identities and extraction provenance.

## Acceptance criteria for extraction approval

The proposal is ready to implement if Steward and Architect agree that:

1. the Distiller is sufficiently independent to justify a dedicated repository;
2. voxel-engine remains a reference consumer and proving corpus rather than the generic system's architectural owner;
3. extraction occurs before the Phase-6 production interfaces are frozen;
4. semantic and authority contracts remain unchanged during extraction;
5. extraction parity is a blocking gate before further productization;
6. project-owned canonical memory and authority state are not accidentally migrated into generic ownership;
7. future generalization is driven by additional project evidence rather than speculative ontology growth.

## Requested review

### Steward review

Review the proposal for:

- semantic and admission authority boundaries;
- ownership of canonical/project-specific artifacts;
- preservation of provenance and immutable evaluation evidence;
- extraction-parity requirements;
- whether the proposed generic/project boundary is safe for routine Steward reconciliation.

The Steward should record approval, requested changes, or rejection with specific reasoning.

### Architect review

Review the proposal for:

- repository and package boundaries;
- generic core versus project-adapter separation;
- dependency direction;
- migration sequencing;
- versioning and release topology;
- risks of premature abstraction or split-brain implementation;
- whether Phase 6 should proceed in the standalone repository as proposed.

The Architect should explicitly identify any architectural changes required before extraction begins.

## Decision record expected

After both reviews, produce a single disposition containing:

- Steward recommendation;
- Architect recommendation;
- required amendments, if any;
- final extraction decision;
- approved extraction invariants;
- approved next implementation step.

No repository extraction should begin until that disposition is recorded.
