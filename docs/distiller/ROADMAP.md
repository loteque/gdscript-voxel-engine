# Reasoning Distiller Roadmap

## Goal

Deliver a production-ready semantic producer that distills observable engineering work into provenance-backed `rgp/1` candidate graphs while preserving a strict authority boundary:

```text
observable evidence
    -> Distiller candidate
    -> deterministic RGP validation
    -> immutable submission
    -> Project Engineering Steward reconciliation
    -> deterministic exact-base proof
    -> exact PEMS/COVE installation
    -> immutable disposition
```

The Distiller produces candidates only. It does not reconstruct hidden chain-of-thought, decide canonical truth, reconcile semantic identity, authorize admission, or write canonical PEMS/COVE.

## Current semantic contract

`rgp/1` is the production candidate protocol unless changed through an explicit compatibility/evaluation process.

Record kinds: `observation`, `decision`, `assumption`, `uncertainty`, `claim`.

Relations: `supports`, `contradicts`, `depends_on`, `supersedes`.

Provenance roles: `primary`, `corroborating`, `context`.

Normative authority remains external to RGP. `validated_by` is not an RGP relation.

## Completed evaluation and integration phases

### Phase 0 — Corpus and Evaluation Baseline

**Status: complete.**

A fixed corpus, expected outcomes, adversarial pressure cases, and scoring rubric establish repeatable evaluation of durable recall, precision, relation integrity, provenance, authority/epistemic safety, and compression.

### Phase 1 — Distiller Agent Prototype

**Status: complete; repeated-run stability passed.**

Fresh independent runs demonstrated stable candidate production across the core corpus without hard failures or authority leakage.

### Phase 2 — Producer/Validator Integration

**Status: complete.**

Raw Distiller output passes the authoritative deterministic RGP validator unchanged, while malformed fixtures fail mechanically without producer-specific exceptions.

### Phase 3 — Shadow Operation

**Status: complete.**

Real project work demonstrated low-review-burden candidate production across architecture, performance, policy, unresolved investigation, and scoped-feature reasoning shapes without automatic canonical mutation.

### Phase 4 — Routine Steward-Governed Admission

**Status: complete.**

Multiple routine candidates traversed immutable submission, Steward semantic reconciliation, exact-base PEMS/2 proof, exact candidate persistence, guarded installation, and immutable disposition.

### Phase 5 — Guarded Admission Automation

**Status: complete for the proven mechanical class.**

The repository automates validation, deterministic proof, evidence persistence, concurrency checks, and exact-byte installation after a separately authored Steward reconciliation transaction.

Authority invariant:

- Distiller: candidate production only.
- Project Engineering Steward: semantic reconciliation and admission authority.
- Executor: deterministic execution only; no semantic reconciliation.

## Phase 6 — Production Orchestration and Hardening

**Status: next production gate.**

Phase 6 turns the proven evaluation/admission machinery into a routine production subsystem without changing its semantic or authority contracts.

### 6.1 Stable producer interface

- Define one versioned Distiller invocation contract.
- Accept a standardized observable-evidence envelope.
- Emit immutable `rgp/1` candidates only.
- Remove evaluation-specific/manual candidate packaging from the normal path.
- Ensure the Distiller has no canonical-memory write capability.

**Acceptance:** the same producer interface handles representative repository tasks without task-specific choreography.

### 6.2 Standard evidence capture

- Define a versioned evidence-envelope schema.
- Support immutable references to owner instructions, PRs, commits, repository observations, tool output, tests, validation results, artifacts, and unresolved outcomes.
- Bind evidence identity/digests where practical.
- Reject missing or malformed required evidence before semantic production.

**Acceptance:** production candidates can be traced back to immutable or auditable observable evidence without reconstructing chat history.

### 6.3 Automatic validation and submission packaging

- Invoke the authoritative RGP validator automatically after production.
- Fail malformed candidates before Steward surfaces.
- Package passing candidates as immutable submissions automatically.
- Preserve raw candidate bytes unchanged.
- Make retries idempotent for the same candidate identity.

**Acceptance:** candidate -> validator -> immutable submission requires no manual file choreography and grants no admission authority.

### 6.4 Steward reconciliation surface

- Keep the Project Engineering Steward as the sole semantic reconciliation/admission authority.
- Provide the Steward with candidate, evidence, relevant canonical context, and deterministic diagnostics.
- Support explicit reuse, creation, guarded update, rejection, provisional treatment, uncertainty preservation, provenance resolution, and relation decisions.
- Produce a separate immutable Steward-authored admission transaction.

**Acceptance:** no Distiller or executor component can silently decide semantic identity or canonical truth.

### 6.5 Deterministic canonical execution

- Use the existing guarded executor as the only normal canonical write path.
- Require exact canonical base matching.
- Require the exact Steward transaction/digest.
- Persist proof artifacts before canonical mutation.
- Install exact proved PEMS/COVE bytes only.
- Verify exact installed bytes after write.
- Preserve immutable disposition evidence.

**Acceptance:** every production canonical change is reproducible from a Steward-authorized transaction and persisted proof evidence.

### 6.6 Failure-path pressure suite

Deliberately test and preserve evidence for:

- stale canonical base;
- branch movement between proof and installation;
- wrong reconciliation digest;
- conflicting or superseded Steward plans;
- reused-record before-state mismatch;
- duplicate record IDs or malformed references;
- malformed/missing evidence;
- duplicate submission/retry;
- no-op installation;
- executor interruption before proof persistence;
- interruption after proof persistence but before installation;
- interruption after installation but before disposition.

**Acceptance:** every pressure case fails closed or recovers deterministically with no unauthorized semantic decision and no partial canonical corruption.

### 6.7 Idempotency and recovery

- Define stable submission and transaction identities.
- Define safe retry behavior for each lifecycle stage.
- Detect already-persisted proof artifacts and already-installed exact candidates.
- Define recovery when disposition lags installation.
- Define how a Steward replaces/supersedes an unexecuted transaction.
- Never repair immutable producer or Steward artifacts in place.

**Acceptance:** retrying or recovering any production stage cannot duplicate canonical meaning or apply a transaction twice.

### 6.8 Authoritative lifecycle state machine

Define machine-readable states for at least:

- candidate produced;
- validation failed;
- awaiting Steward;
- reconciliation active;
- rejected/provisional;
- awaiting execution;
- execution requested;
- proof failed;
- proof persisted;
- installation failed;
- installed;
- disposed.

State must be derived from authoritative immutable artifacts/workflow evidence rather than manually maintained dashboard state.

**Acceptance:** an orchestrator can determine exactly what is waiting, active, failed, installed, or complete and identify the responsible boundary.

### 6.9 Permission and branch protection

- Give the Distiller read/evidence/submission capability only.
- Restrict Steward reconciliation surfaces to the Steward authority.
- Restrict canonical write capability to the deterministic executor.
- Protect canonical files/branches against bypass of the governed path.
- Keep execution authorization distinct from semantic reconciliation authority.

**Acceptance:** credentials and repository protections enforce the documented authority model rather than merely relying on convention.

### 6.10 Versioning and compatibility

- Freeze production versions for RGP, evidence envelopes, submissions, Steward transactions, PEMS/2, and COVE generation.
- Define upgrade and deprecation rules.
- Preserve replayability of old submissions and proof evidence.
- Require evaluation pressure before semantic vocabulary changes.

**Acceptance:** a protocol upgrade cannot silently reinterpret previously admitted knowledge.

### 6.11 Operational metrics and alerts

Track at minimum:

- candidate/validation volume;
- validation rejection rate;
- Steward queue age;
- Steward rejection/provisional/admission rates;
- new/reused/updated canonical record counts;
- reconciliation-plan correction count;
- stale-base and concurrency failures;
- executor/proof/install failures;
- retry/recovery frequency;
- review burden.

Alert on stuck Steward queues, repeated validation/proof failures, installation failures, and recovery-required states.

The dashboard is an optional projection of these metrics, not an authority source.

**Acceptance:** production failures and stalled work are observable without inspecting raw repository history manually.

### 6.12 Production runbook

Document:

- normal candidate-to-admission operation;
- Steward rejection/provisional handling;
- retry and recovery procedures;
- stale-base reconciliation;
- transaction replacement/supersession;
- contract upgrades;
- emergency disable/kill switch;
- canonical rollback/recovery boundaries;
- ownership of each authority and execution stage.

**Acceptance:** a maintainer can operate and recover the system without relying on undocumented evaluation-session knowledge.

### 6.13 Final production acceptance batch

Run a fresh production-shaped batch covering multiple real reasoning shapes plus deliberate failures.

The batch must include:

- several successful admissions;
- canonical semantic reuse;
- a guarded existing-record update;
- an unresolved uncertainty preserved through admission;
- at least one Steward rejection;
- at least one duplicate/no-op case;
- stale-base/concurrency failure;
- invalid-plan/digest failure;
- interrupted/retried execution or an equivalent deterministic recovery test.

**Production exit criterion:** all production acceptance cases demonstrate zero Distiller reconciliation/admission authority, zero executor semantic reconciliation, zero partial canonical corruption, deterministic/auditable recovery, and acceptable Steward review burden.

## Production Definition of Done

The Distiller system is production-ready when:

1. observable work enters through a stable evidence contract;
2. Distiller production, validation, and immutable submission are routine and idempotent;
3. Steward semantic reconciliation is the only canonical semantic authority path;
4. deterministic proof/install is the only normal canonical write path;
5. lifecycle, retries, failures, and recovery are explicit and machine-readable;
6. permissions enforce the authority boundary;
7. contracts are versioned and replayable;
8. operations are measurable and alertable;
9. the runbook is complete;
10. the final production acceptance batch passes.

## Deferred unless demonstrated necessary

- hidden chain-of-thought storage;
- automatic causal inference;
- automatic semantic identity reconciliation;
- Distiller self-admission;
- autonomous architectural/policy admission;
- large generic reasoning ontologies;
- a dedicated Distiller database;
- a long-running service when repository/workflow orchestration is sufficient;
- domain-specific voxel-engine record kinds in generic RGP.

## Continuing Evaluation Questions

1. Can another agent reconstruct the durable argument without the original chat?
2. Are empirical propositions traceable to supplied evidence?
3. Are observation, decision, interpretation, assumption, and uncertainty preserved without promotion?
4. Are premise and general relation types used distinctly?
5. Is the Distiller inventing causality, identity equivalence, or authority?
6. Is provenance minimal, sufficient, and non-fabricated?
7. Is low-value activity excluded?
8. Are fresh runs stable enough for practical Steward review?
9. Does automation preserve the Distiller -> Steward -> executor authority separation?
10. Can every canonical mutation be reproduced and audited from immutable evidence?
