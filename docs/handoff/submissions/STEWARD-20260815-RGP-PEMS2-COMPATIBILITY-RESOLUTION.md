# Steward Submission: RGP / PEMS2 Compatibility Resolution

- submission: `STEWARD-20260815-RGP-PEMS2-COMPATIBILITY-RESOLUTION`
- timestamp: `2026-08-15T21:34:00-07:00`
- author: Project Engineering Steward submission on behalf of the project owner
- recipient: Engineering Knowledge Systems Architect
- status: review-requested
- acknowledges: `ARCH-20260815T193249-0700-025`
- subject: Resolution of the seven PEMS/2 RGP compatibility design questions

## Context

The Architect accepted the RGP direction in `ARCH-20260815T193249-0700-025` and recommended a closed `pems/2` proposition capability, while leaving seven design questions open before a successor schema could be frozen.

The project owner authorized resolving those questions. The complete design work and pressure evaluation were performed on feature branch `pems-mapping-reconciliation`.

Authoritative proposal artifacts for review:

- `docs/distiller/PEMS2_RGP_COMPATIBILITY_PROFILE.md`
- `docs/distiller/evaluation/pems2-rgp-compatibility-cases.yaml`
- `docs/distiller/evaluation/results/2026-08-15-pems2-rgp-compatibility-profile-evaluation.md`

Latest resolution commit on that branch:

- `941db7cb75154a0e0225874275363dbe054f2994`

The 20 compatibility pressure cases all have explicit semantics-preserving dispositions.

## Resolved questions

### 1. Domain-record proposition profile

For the initial `pems/2` RGP compatibility profile, only these existing domain records are proposition-capable by explicit profile:

- `decision` -> RGP `decision` using the accepted decision statement/summary;
- unresolved `unresolved_item` -> RGP `uncertainty` using the unresolved statement/summary.

Generic RGP `observation`, `assumption`, and `claim` map to the new generic PEMS `proposition` record unless a future explicitly frozen lossless domain profile exists.

No other domain record is heuristically promoted into a reasoning proposition. Domain participation must be explicitly versioned and proven lossless.

### 2. Resolved uncertainty export

RGP export is snapshot-scoped.

An `unresolved_item` exports as RGP `uncertainty` only for a memory snapshot in which that record is unresolved/currently uncertain. A later resolved historical record does not get rewritten as though uncertainty never existed, nor does current-state export pretend the uncertainty remains live.

Historical reconstruction must use the relevant historical PEMS state/observation boundary.

### 3. Contradiction symmetry

`contradicts` is semantically symmetric but canonically stored once.

Canonical identity uses deterministic endpoint ordering rather than storing two opposite edges. Query semantics must treat either endpoint as contradicting the other.

This avoids duplicate canonical edge identities while preserving the symmetric meaning of contradiction.

### 4. `depends_on` semantic breadth

`depends_on` remains one relation family, but `pems/2` freezes a closed dependency profile instead of leaving the relation semantically vague.

Initial dependency kinds:

- `conditional_validity`: RGP-compatible meaning; the source proposition's validity/applicability may require revision if the target changes;
- `structural`: existing project-domain structural dependency semantics;
- `legacy_untyped`: migration-only representation for v1 dependencies whose narrower meaning cannot be inferred safely.

Native RGP `depends_on` imports as `conditional_validity`.

The migration profile must not invent dependency semantics for existing `pems/1` edges.

### 5. Generic proposition promotion

An admitted generic proposition is never mutated in place into a different domain record kind and its canonical ID is never rebound.

If later evidence/governance establishes a more precise domain record, admission creates or reconciles that domain identity and records reviewed supersession/refinement according to PEMS lifecycle policy. Reasoning edges are migrated or related transactionally under Steward admission rules, while the former proposition remains historically preserved.

This protects stable semantic identity and prevents silent ontology mutation.

### 6. Atomicity of typed provenance enrichment

Typed provenance enrichment is an ordinary atomic update to the admitted proposition/relation when it adds evidence without changing proposition meaning.

Rules:

- adding a new corroborating or context source observation may enrich the same proposition;
- moving an existing observation between provenance roles is semantic reclassification and requires review/transactional replacement of the provenance envelope;
- changed source content is represented by a new immutable `source_observation`, never mutation of the old observation;
- provenance changes that materially change the proposition itself require a new/reconciled proposition identity rather than evidence-only enrichment.

Authority remains source-chain-derived; provenance-role updates do not create authority.

### 7. RGP version binding

The initial `pems/2` compatibility profile targets **`rgp/1`**.

PEMS tooling must reject unknown RGP major versions unless an explicit compatibility/migration profile exists. Minor evolution within `rgp/1` is compatible only where the RGP contract explicitly defines it as such; PEMS must not infer compatibility from version numbers alone.

A future RGP major version does not silently alter `pems/2` semantics.

## Preserved architecture constraints

- `pems/1` remains frozen.
- `cove/1` remains frozen and domain-agnostic.
- The proposed work is a successor semantic profile, not reinterpretation of canonical v1 bytes or fixtures.
- RGP proposition kind remains independent from PEMS admission, lifecycle, truth, and authority.
- Typed provenance terminates at immutable `source_observation` records.
- Existing v1 provenance migrates to `provenance.untyped` rather than inventing primary/corroborating/context semantics.
- Existing identities and historical lifecycle state remain stable through v1 -> v2 migration.
- Lossy v2 -> v1 downgrade must fail explicitly when v2-only meaning is present.
- No canonical-memory migration is authorized by this submission.

## Requested Architect disposition

Please review the seven resolutions and either:

1. accept them as the compatibility profile for a bounded `pems/2` semantic-contract design tranche;
2. amend specific resolutions with concrete semantic/compatibility requirements; or
3. reject a resolution with the invariant it violates.

If accepted, the next tranche should draft normative successor schema/semantic contracts and compatibility fixtures only. It should not migrate canonical project memory.

## Human reasoning

The earlier RGP mapping work established that `pems/1` lacks enough proposition, relation, and provenance semantics to preserve RGP losslessly. The Architect correctly recommended a small closed successor rather than turning PEMS into an arbitrary extensibility mechanism.

These seven resolutions close the remaining ambiguity around where generic propositions meet existing domain records, how time and history affect uncertainty, how symmetric and conditional relations are canonicalized, how identities evolve toward more precise domain representations, how evidence can change without silently changing claims, and exactly which RGP protocol PEMS/2 promises to understand.

The goal is a compatibility boundary that is explicit enough to implement and test without making the successor ontology larger than the demonstrated need.