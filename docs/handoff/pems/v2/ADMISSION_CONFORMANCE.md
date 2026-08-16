# PEMS/2 Admission, Validation, and Conformance Contract

## Boundary

PEMS/2 separates four questions that must not collapse into one:

1. **Structural validity:** does the document satisfy `pems-v2.schema.json`?
2. **Semantic validity:** are references, lifecycle, provenance, reasoning, and version rules coherent?
3. **Admission:** should a valid candidate become durable/canonical project memory, and under which stable identity?
4. **Authority:** what governed source chain, if any, gives the represented proposition normative standing?

A structurally valid candidate is not automatically true, admitted, current, or authoritative.

## Semantic validation requirements

A conforming validator must reject:

### Identity and graph

- duplicate record or relation IDs;
- a record and relation sharing one stable ID if the implementation's namespace policy forbids it;
- dangling relation endpoints;
- dangling `supersedes` / `superseded_by` references;
- non-reciprocal supersession where reciprocal lifecycle metadata is required;
- identity rebinding detected against an admitted identity registry;
- duplicate values in any ID/reference array.

### Provenance

- provenance references that do not resolve to `source_observation`;
- empty role arrays;
- the same source-observation reference appearing in multiple roles of one provenance envelope;
- provenance role inferred from source ID spelling;
- mutation of an immutable source observation to represent changed source content.

PEMS/2 does not infer source authority from `primary`, `corroborating`, `context`, or `untyped`.

### Generic propositions

- proposition kinds outside `observation`, `assumption`, `claim`;
- epistemic roles outside `asserted`, `derived`;
- a `derived` proposition with no `derived_from` premise in the validated snapshot;
- a `derived_from` relation whose source is not proposition-capable under the relevant profile;
- automatic domain-kind mutation of an existing generic proposition identity.

The first successor contract deliberately does **not** freeze a universal minimum-provenance rule for all proposition kinds. Distiller experiments suggest useful grounding policies, but grounding minima remain admission-policy concerns until separately governed. This avoids converting experimental evidence into an unreviewed schema rule.

### Relations

- self-edge `contradicts`;
- noncanonical endpoint order for `contradicts`;
- duplicate contradiction pairs regardless of input direction;
- `depends_on` without `dependency_kind`;
- `dependency_kind` outside the closed profile;
- native PEMS/2 creation of `legacy_untyped` except through deterministic v1 migration or explicit retained legacy evidence;
- interpreting `structural` as RGP conditional validity.

### RGP/1 compatibility

A lossless current-state exporter must reject direct domain proposition export unless:

```text
decision:
  lifecycle == current
  decision_state == accepted

unresolved_item:
  lifecycle == current
  resolution_state in {open, blocked, deferred}
```

Historical accepted decisions and historical unresolved items require historical-snapshot export. They must not be made current by export.

Unknown RGP major versions are rejected.

## Admission contract

Admission receives a semantically valid candidate graph, existing canonical identities, resolved provenance, and Steward policy.

Allowed outcomes are governance outcomes, not PEMS proposition kinds:

- admitted;
- provisional;
- rejected.

Implementations may store these outcomes outside the semantic graph. They must not encode admission status by changing `proposition_kind`, `epistemic_role`, source authority, or PEMS lifecycle.

### Required admission invariants

Admission must:

- reconcile semantic equivalence before allocating a new canonical identity;
- preserve an existing stable identity when the represented semantic object is unchanged;
- allocate/use a distinct identity when a generic proposition is refined into a domain record;
- preserve historical records and provenance through supersession;
- retain contradictions/conflicts explicitly rather than overwrite them;
- preserve all required premise edges for derived propositions;
- resolve relation endpoints to the resulting admitted graph;
- perform connected record/relation changes transactionally when partial admission would create dangling or semantically false graph state;
- fail rather than invent provenance or normative authority.

### Review-required initial policy

Until separately proven safe, these are review-required:

- project decisions and other normative-domain changes;
- generic `claim` admission;
- conflict resolution;
- supersession;
- provenance role reclassification;
- any operation changing current canonical understanding;
- generic proposition -> domain refinement.

Recency alone never establishes supersession.

## Provenance enrichment transaction

Ordinary evidence enrichment may preserve identity when proposition/relation meaning is unchanged. The transaction must validate the whole resulting provenance envelope.

`untyped -> typed` classification is atomic: the reference is removed from `untyped` and added to exactly one typed role in one committed update.

Typed-role changes, deletion of typed grounding, or correction of incorrect grounding are review-required semantic corrections.

## Conformance tiers

### Tier A: structural

- JSON Schema draft 2020-12 schema itself is valid;
- success fixtures satisfy structural schema;
- malformed fixtures fail.

### Tier B: semantic

- reference integrity;
- provenance integrity;
- lifecycle/supersession integrity;
- contradiction canonicalization;
- depends-on profile;
- generic proposition premise requirements;
- deterministic normalization.

### Tier C: migration

- same v1 input migrates identically on repeated runs;
- all v1 IDs and domain states preserved;
- v1 observation refs become only `provenance.untyped`;
- all v1 dependencies become `legacy_untyped`;
- no v2-only proposition/reasoning meaning is invented;
- lossless-subset downgrade reconstructs normalized v1;
- lossy downgrade fails explicitly.

### Tier D: RGP compatibility

Every case in `RGP_COMPATIBILITY_FIXTURES.json` must have one deterministic disposition. In particular the negative lifecycle cases are acceptance gates, not documentation examples.

### Tier E: admission simulation

Fixtures must demonstrate:

- equivalent candidate reconciliation without duplicate identity;
- distinct identity for domain refinement;
- transactional premise/relation admission;
- unresolved provenance prevents grounded admission;
- conflict is preserved rather than overwritten;
- source recency alone does not supersede history.

## Determinism

Conformance must compare normalized structures and, when using the repository's canonical JSON serializer, exact UTF-8 bytes.

At least two independent repeated executions of migration and fixture classification must produce identical output hashes.

Determinism is not permission to change canonical memory. It is evidence for the later Steward migration gate.

## Freeze/cutover gate

This draft is technically reviewable when all contract files exist and the local deterministic conformance suite passes.

Canonical adoption remains a different state. Before any PEMS/2 cutover, the Steward/owner must separately approve:

- the final successor contract;
- real-corpus migration evidence against current canonical memory;
- stable-identity and historical/provenance preservation evidence;
- deterministic byte/human reconstruction evidence;
- downgrade/compatibility behavior;
- the serialization strategy for PEMS/2 (including whether COVE/1 can encode it without contract change);
- exact canonical authority/cutover procedure.

This tranche does not answer or authorize that later authority decision.
