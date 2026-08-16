# PEMS/2 Successor Contract Draft

Status: **normative draft for Steward review; noncanonical**.

Authority: bounded successor-contract tranche authorized by `STEWARD-20260815-020`, preserved by `STEWARD-20260815-021`, and based on `ARCH-20260815T215952-0700-026`.

This directory defines the proposed `pems/2` semantic contract, deterministic `pems/1 -> pems/2` migration, the initial `rgp/1` compatibility profile, and admission/conformance rules. It does **not** migrate canonical project memory. `pems/1`, `cove/1`, and `jcs/1` remain frozen and authoritative for the current canonical corpus until a separate owner/Steward cutover decision.

## 1. Design invariants

PEMS/2 is a closed successor, not a generic extension namespace.

1. Stable semantic identity is preserved when meaning is preserved. Schema evolution alone never changes an ID.
2. A record may not change canonical identity merely because a more specialized record kind later becomes available.
3. Lifecycle, admission state, proposition kind, epistemic role, authority, and provenance are distinct concepts.
4. Authority remains derived from source/source-observation chains and project governance. Admission never creates authority.
5. Historical state is preserved. Current-state export may not flatten proposed, rejected, superseded, resolved, or historical records into current RGP propositions.
6. Provenance terminates at immutable `source_observation` records.
7. `pems/1` provenance migrates conservatively to `provenance.untyped`. Typed roles are never inferred during migration.
8. Existing `pems/1` `depends_on` relations migrate to `dependency_kind=legacy_untyped`. Narrower semantics are never guessed.
9. `contradicts` is symmetric in meaning and stored once with deterministic endpoint ordering.
10. Unknown RGP major versions fail closed.

## 2. New PEMS/2 semantic capability

PEMS/2 adds one generic record kind:

`proposition`

Its data contains:

- `statement`: durable proposition text;
- `proposition_kind`: one of `observation`, `assumption`, `claim`;
- `epistemic_role`: one of `direct`, `derived`.

`proposition_kind` describes what the proposition asserts. `epistemic_role` describes how the proposition is epistemically situated. A derived empirical synthesis may therefore remain an `observation` with `epistemic_role=derived`; derivation does not force a new proposition kind.

PEMS domain records retain their existing meanings. The initial RGP compatibility profile permits direct domain proposition participation only for:

- a **current** `decision` whose `data.decision_state == "accepted"`, exported as RGP `decision`;
- a **current** `unresolved_item` whose `data.resolution_state` is `open`, `blocked`, or `deferred`, exported as RGP `uncertainty`.

All other generic RGP observations, assumptions, and claims are represented as PEMS `proposition` records. No domain record is heuristically promoted because it contains prose.

## 3. Provenance

PEMS/2 replaces v1 `observation_refs` on records and relations with a provenance envelope:

- `primary`
- `corroborating`
- `context`
- `untyped`

Every entry is a stable ID of an immutable `source_observation`.

The roles are evidentiary roles, not authority levels.

`untyped` exists for deterministic migration and for evidence whose role has not been governed. A source observation must not appear in more than one role on the same object.

Adding new evidence without changing meaning is ordinary atomic enrichment. Moving an existing observation between roles, deleting typed evidence, or replacing incorrect grounding is a governed semantic correction. Changed external content always creates a new `source_observation`.

## 4. Relations

PEMS/2 retains v1 relation kinds and adds:

- `supports`: source proposition strengthens target proposition but is not a constitutive premise;
- `contradicts`: endpoints conflict; symmetric semantics, one canonical edge.

`derived_from` remains the PEMS relation corresponding to an RGP premise.

`depends_on` gains a required closed qualifier when used:

- `conditional_validity`: RGP-compatible conditional validity/applicability;
- `structural`: project-domain structural dependency;
- `legacy_untyped`: migration-only encoding for v1 dependency meaning that cannot be narrowed safely.

Native RGP `depends_on` imports only as `conditional_validity`. A native PEMS/2 relation must not use `legacy_untyped`; that value is valid only when `data.migration_origin == "pems/1"`.

For `contradicts`, canonical storage requires `from < to` by Unicode code-point comparison of stable IDs. Two opposite-direction contradiction edges for one pair are invalid duplicates. Query semantics are symmetric.

## 5. RGP/1 compatibility

The profile binds exactly to RGP major `rgp/1`.

### RGP -> PEMS/2

- `observation` -> `proposition(observation)`
- `assumption` -> `proposition(assumption)`
- `claim` -> `proposition(claim)`
- `decision` -> PEMS `decision` only when admission can represent the complete PEMS decision semantics losslessly; otherwise it remains provisional outside canonical memory
- `uncertainty` -> `unresolved_item` only when consequential and unresolved; otherwise provisional

Relations:

- RGP premise -> `derived_from`
- RGP supports -> `supports`
- RGP contradicts -> canonical single-edge `contradicts`
- RGP depends_on -> `depends_on(conditional_validity)`
- RGP supersedes -> governed PEMS supersession, never a purely syntactic import

### PEMS/2 -> current-state RGP

A direct domain export is lossless only when:

- `decision`: lifecycle is `current` and `decision_state` is `accepted`;
- `unresolved_item`: lifecycle is `current` and `resolution_state` is `open`, `blocked`, or `deferred`.

Proposed, rejected, superseded, historical, tombstoned, or otherwise non-current decisions are not bare current RGP decisions. Resolved or historical unresolved items are not current RGP uncertainties. Historical reasoning reconstruction uses the corresponding historical PEMS snapshot/observation boundary.

Generic propositions export according to their `proposition_kind`, subject to complete relation/provenance compatibility.

Unknown RGP major versions are rejected. PEMS tooling must not infer compatibility from version-number resemblance.

## 6. Identity and refinement

Generic proposition refinement is **refinement by supersession**, never kind mutation.

When governance establishes a precise domain representation for a previously admitted generic proposition:

1. admit or reconcile a distinct domain identity;
2. preserve the original proposition identity and history;
3. establish reviewed equivalence/replacement;
4. use governed supersession when the domain record replaces the proposition as current understanding;
5. transfer or recreate reasoning edges only when independently established by the reconciliation transaction.

No automatic edge retargeting occurs from text similarity.

## 7. Snapshot semantics

Lifecycle is part of meaning.

Current-state projection evaluates the selected PEMS snapshot. Historical RGP reconstruction must select the historical PEMS state that actually contained the reasoning state. A later snapshot cannot rewrite earlier proposed decisions, rejected decisions, or unresolved uncertainty into a different historical meaning.

## 8. Structural versus semantic validation

`pems-v2.schema.json` validates document shape.

`validate_pems2_contract.py` additionally checks semantic invariants not expressible cleanly in JSON Schema, including:

- unique stable IDs across records and relations;
- reference resolution;
- provenance targets are `source_observation`;
- provenance-role disjointness;
- `derived_from`, `supports`, `contradicts`, and RGP-profile relation endpoint suitability;
- canonical contradiction ordering and duplicate-pair rejection;
- `depends_on` qualifier rules;
- source-observation immutability assumptions supplied by the migration/conformance boundary;
- direct RGP domain-export lifecycle/state restrictions;
- exact RGP major binding;
- deterministic migration fixture equality.

## 9. Conformance bar

A PEMS/2 implementation is conformant to this draft only if it can demonstrate:

- structural and semantic validation;
- deterministic v1 -> v2 migration;
- stable-ID preservation for unchanged semantic objects;
- zero invented typed provenance in migration;
- zero invented dependency semantics in migration;
- state-preserving RGP projection negatives;
- symmetric contradiction query behavior from one canonical edge;
- fail-closed unknown RGP majors;
- explicit failure of lossy v2 -> v1 downgrade when v2-only semantics exist;
- transactional admission with no dangling graph references;
- deterministic output under the repository's separately versioned byte-canonicalization contract when/if one is later authorized for PEMS/2.

## 10. Authorization boundary

These artifacts are successor design and conformance evidence only.

They do not:

- change canonical authority;
- reinterpret or mutate `pems/1`;
- redesign `cove/1`;
- change `jcs/1`;
- migrate `docs/project-chat-handoff.cove.json`;
- migrate `docs/project-chat-handoff.json`;
- admit experimental Distiller output into canonical memory.

The next gate after this draft is Steward review of the normative semantics, schema, migration determinism, fixtures, and conformance evidence. Canonical migration remains a later and separate gate.
