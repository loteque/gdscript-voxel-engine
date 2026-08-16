# PEMS Architecture Assessment: Native RGP Support

## Disposition

**Accept direction and propose successor PEMS design.**

The demonstrated mapping losses justify a versioned PEMS schema evolution. They are not accidental adapter omissions: the frozen `pems/1` contract deliberately has a closed 20-kind project-domain vocabulary, untyped `observation_refs`, and no generic proposition, support, or contradiction semantics. The mapping evaluation correctly leaves unsupported RGP meaning provisional rather than coercing it into adjacent PEMS kinds.

The recommended successor is **`pems/2`**, with a small first-class proposition capability integrated into the existing PEMS graph. It should not be a generic arbitrary extension escape hatch, and it should not make the RGP wire shape itself the PEMS schema. RGP remains an independent domain-neutral protocol; PEMS/2 should implement a protocol-neutral semantic subset that can losslessly import/export RGP core meaning.

This assessment is design only. It does not authorize implementation, migration, canonical-memory changes, or modification of `pems/1`.

## 1. Do the demonstrated mapping losses justify evolution?

Yes.

The 14-case reconciliation evaluation establishes deterministic behavior for the current partial mapper and confirms six semantic losses that `pems/1` cannot represent losslessly:

- generic assumptions;
- generic empirical observations as propositions;
- generic logical/evidentiary claims;
- proposition-to-proposition `supports`;
- proposition-to-proposition `contradicts`;
- typed provenance roles (`primary`, `corroborating`, `context`).

These losses cut across all three major reasoning dimensions: node semantics, edge semantics, and provenance semantics. A sidecar can preserve them operationally, but then durable reasoning identity, lifecycle, provenance, reconciliation, and history would be split across two canonical graphs. That would duplicate precisely the governance machinery PEMS already owns.

The evidence does **not** justify making every RGP node a new PEMS domain entity. The correct conclusion is narrower: PEMS needs a generic proposition primitive and reasoning relations in addition to its existing domain ontology.

## 2. Proposition family versus general extension mechanism

PEMS/2 should add a **first-class proposition family**, not a general arbitrary extension mechanism.

A free-form extension mechanism would weaken the closed-schema discipline that protects PEMS from semantic escape hatches. The frozen v1 rule that every admitted kind has a normative schema remains a good architectural invariant.

The smallest coherent addition is one generic record kind:

```text
kind: proposition

data:
  proposition_kind: observation | assumption | claim
  statement: non-empty atomic proposition
```

`decision` and `uncertainty` should **not** automatically become generic proposition records when a lossless existing PEMS domain representation exists. Existing PEMS `decision` and `unresolved_item` records should be proposition-capable graph nodes for reasoning relations. This prevents duplicate canonical representations of the same project decision or unresolved item.

The initial proposition-kind set in PEMS/2 should therefore be limited to the currently uncovered RGP kinds: `observation`, `assumption`, and `claim`. The RGP import/export profile maps:

- RGP `decision` -> PEMS `decision` when domain admission requirements are satisfied;
- RGP consequential `uncertainty` -> PEMS `unresolved_item` when it is truly a project unresolved item;
- RGP `observation`, `assumption`, or `claim` -> generic PEMS `proposition` when no more precise lossless domain kind exists;
- any RGP proposition with a more precise existing PEMS domain representation -> that domain record, not a duplicate generic proposition.

If a candidate cannot be represented losslessly by either an existing domain kind or the generic proposition contract, it remains provisional. The presence of `proposition` must not become permission to erase domain-specific semantics.

## 3. Premise and general relation semantics

### Premise / derivation

RGP `premise` should normalize to the existing PEMS `derived_from` relation rather than introduce a second constitutive-derivation edge.

For RGP-compatible reasoning nodes, PEMS/2 semantic validation should additionally require:

- every `derived_from` endpoint resolves;
- no self-reference;
- the constitutive premise subgraph is acyclic;
- admission of a derived node cannot drop required premise edges.

Syntax does not need to match RGP as long as import/export is lossless.

### `supports`

Add `supports` as a first-class PEMS/2 relation kind. It is explicitly non-derivational and must never be normalized to `derived_from` or provenance.

### `contradicts`

Add `contradicts` as a first-class PEMS/2 relation kind. Contradiction preserves both endpoints and does not imply supersession, rejection, or lifecycle mutation.

The relation may be represented canonically in one directed orientation for deterministic identity, but its semantic contract should define whether contradiction is symmetric for querying. Do not silently duplicate two canonical edges merely to simulate symmetry.

### `depends_on`

Reuse the existing PEMS `depends_on` relation only after the successor contract explicitly freezes its meaning broadly enough to include RGP's conditional-validity/applicability semantics. The current mapping evidence treats the correspondence as lossless, so no second RGP-only edge is presently justified.

If implementation review discovers that existing project-domain `depends_on` has materially broader or different semantics, the successor design must introduce an explicit relation qualifier/profile instead of overloading one spelling with incompatible meanings.

### `supersedes`

Reuse PEMS supersession machinery, but keep candidate relation semantics separate from lifecycle authority.

An RGP candidate may assert `supersedes`; that assertion does not itself mutate canonical memory. Once the relation is admitted as established supersession under Steward policy, PEMS lifecycle fields and supersession references must be updated transactionally and the superseded record remains historically preserved.

Recency is never sufficient evidence for supersession.

## 4. Typed provenance and source/source-observation reuse

PEMS/2 should preserve the existing stable `source` / immutable `source_observation` model and make typed provenance roles point to **source observations**, never directly to mutable sources.

The clean successor common provenance shape is conceptually:

```json
"provenance": {
  "primary": ["source-observation-id"],
  "corroborating": ["source-observation-id"],
  "context": ["source-observation-id"],
  "untyped": ["source-observation-id"]
}
```

The `untyped` role is required for lossless deterministic migration from `pems/1`: existing `observation_refs` did not assert whether evidence was primary, corroborating, or context. Migrating every v1 reference to `primary` would invent semantics.

PEMS/2 should replace the v1 common `observation_refs` field with this single normalized provenance object rather than maintain two competing provenance authorities. The union of its role arrays is the record/relation's complete evidence reference set.

For native RGP import:

- resolve opaque RGP source identifiers through the source registry;
- reconcile/create stable PEMS `source` identities;
- reconcile/create immutable/unversioned/owner-attested `source_observation` records as required by existing PEMS rules;
- place the resulting observation IDs under their original RGP provenance roles.

Authority remains derived from resolved source chains and governed admission policy. A `primary` provenance role is evidentiary, not an authority bit.

## 5. Avoiding duplicate decisions and unresolved items

PEMS/2 should adopt a **single-representation rule**:

> When one candidate proposition is losslessly representable by an existing PEMS domain record, that domain record is the canonical reasoning node. A second generic proposition with the same semantic identity is invalid unless a separately modeled distinction proves they are different propositions.

This requires the reasoning relations (`derived_from`, `supports`, `contradicts`, `depends_on`, `supersedes`) to be able to target both generic `proposition` records and appropriate existing PEMS domain records.

Minimum correspondence profile:

- PEMS `decision` is RGP-exportable as proposition kind `decision` using `data.summary` as the statement;
- PEMS consequential `unresolved_item` is RGP-exportable as `uncertainty` while unresolved; resolution lifecycle remains a PEMS domain concern;
- other domain records may be RGP-exportable as `observation` or `claim` only through explicit kind-specific profiles proven lossless, not heuristic text conversion.

A generic proposition must never be auto-promoted into a requirement, owner decision, validation result, or other authority-bearing domain kind merely because its wording resembles one.

## 6. Smallest coherent successor contract

Recommend `pems/2` as a major semantic version because the common provenance envelope changes and the closed vocabulary expands.

The smallest coherent delta from `pems/1` is:

1. add record kind `proposition` with closed data:
   - `proposition_kind`: `observation | assumption | claim`;
   - `statement`: atomic non-empty string;
2. add relation kinds `supports` and `contradicts`;
3. retain `derived_from`, `depends_on`, and governed `supersedes` semantics, adding proposition-graph validation where applicable;
4. replace common `observation_refs` with typed `provenance` roles including `untyped` for faithful v1 migration;
5. define a normative RGP compatibility profile specifying which existing PEMS domain records act as RGP proposition nodes and how they import/export;
6. preserve all existing stable-ID, source-observation immutability, historical retention, secret handling, admission, and authority rules.

Do **not** add arbitrary custom record kinds, free-form payload namespaces, generic predicate strings, or RGP-specific source registries in this first successor. Those would increase extensibility faster than governance and validation can safely constrain it.

## 7. Migration and compatibility

### `pems/1` remains frozen

No v1 schema, validator, fixture, or canonical document should be reinterpreted to contain these semantics.

### Deterministic v1 -> v2 migration

A valid normalized `pems/1` document must have a deterministic `pems/2` representation that:

- preserves every existing record and relation ID;
- preserves record kinds, lifecycle, data, supersession, and historical state;
- converts each v1 `observation_refs` collection to `provenance.untyped` without inventing evidence roles;
- creates no generic proposition records solely as a migration side effect;
- preserves COVE as a separate domain-agnostic structural layer.

A reverse `pems/2` -> `pems/1` conversion is only lossless for the v1-compatible subset. Documents containing generic propositions, supports/contradicts edges, or typed provenance roles must fail explicit lossless downgrade rather than silently discard meaning.

### Compatibility behavior

- readers that support only `pems/1` reject `pems/2` rather than guessing;
- PEMS/2 tooling may ingest pems/1 through the explicit deterministic migrator;
- COVE requires no semantic redesign merely because PEMS changes; generic COVE should encode either normalized document if its existing structural contract supports the values;
- canonical-memory adoption of pems/2 requires a separate owner/Steward migration gate and evidence, not this architecture review.

## 8. Validation implications

A successor conformance suite should add fixtures for:

- all three generic proposition kinds;
- exact RGP import/export round trips for all five RGP kinds;
- no duplicate generic proposition when a decision/unresolved-item mapping is lossless;
- premise/`derived_from` acyclicity and dangling/self-reference rejection;
- non-derivational `supports` preservation;
- contradiction coexistence without destructive replacement;
- depends-on correspondence;
- admitted supersession plus lifecycle/history consistency;
- typed provenance role round trip through source-observation resolution;
- v1 provenance migration to `untyped` with no invented role;
- authority derivation remaining source-based rather than proposition/admission-based;
- stable identity under repeated reconciliation;
- explicit lossy-downgrade rejection;
- deterministic PEMS normalization, COVE round trip, JCS bytes, and human reconstruction for the successor model.

The existing 14-case mapping suite should remain as a regression fixture proving `pems/1` stays partial and unchanged.

## 9. Admission implications

RGP structural validity and RGP proposition kind do not grant PEMS admission.

PEMS/2 admission should preserve the current separation:

```text
candidate proposition kind
    != admission state
    != lifecycle
    != normative authority
```

Admission remains transactional over connected graph dependencies. It must reconcile stable identity before rewriting temporary premise/relation endpoints, preserve all required provenance and premise edges, and refuse partial commits that create dangling graph structure.

Initial policy should remain conservative:

- generic assumptions may be admitted when materially constraining, while remaining assumptions;
- uncertainties may be admitted while unresolved;
- decisions and authority-bearing claims remain review-required unless a narrower governed policy is proven;
- contradiction does not choose a winner;
- supersession requires established policy/authority;
- unsupported source resolution keeps the candidate provisional or rejected according to policy.

## 10. Why not a sidecar or arbitrary extension namespace?

A sidecar duplicates stable identity, lifecycle, provenance, history, reconciliation, and canonical transaction boundaries. That is justified only if the reasoning graph has fundamentally different authority or retention semantics. The supplied RGP and admission contracts instead deliberately rely on the same canonical-admission and provenance concerns PEMS already governs.

An arbitrary extension namespace has the opposite problem: it keeps one store but weakens semantic closure. PEMS would no longer be able to guarantee that admitted meaning is backed by a normative schema and validator.

A first-class, closed proposition capability is the smaller and safer middle path.

## Unresolved design questions

The following should be resolved before a successor schema is frozen:

1. **Domain-record proposition profile:** exactly which existing PEMS kinds besides `decision` and `unresolved_item` are permitted as RGP proposition nodes, and what lossless statement/kind projection each uses.
2. **Resolved uncertainty export:** whether a resolved historical `unresolved_item` exports to RGP as the historical uncertainty proposition, or whether RGP export is scoped to the proposition's state at the relevant observation/time.
3. **Contradiction symmetry:** whether canonical `contradicts` relation identity is directional with symmetric query semantics or structurally undirected in the successor model.
4. **`depends_on` semantic breadth:** confirm that existing PEMS `depends_on` is identical enough to RGP conditional-validity semantics; otherwise introduce a closed relation qualifier/profile rather than a duplicate generic predicate.
5. **Generic proposition promotion:** define the governed migration when a previously admitted generic proposition later becomes representable as a more precise domain record without rebinding semantic identity or losing reasoning edges.
6. **Atomicity of typed provenance updates:** determine whether adding corroborating/context evidence to an existing proposition is ordinary provenance enrichment or requires a new proposition/source-observation state under specific source-change conditions.
7. **RGP version binding:** define which RGP major version the PEMS/2 compatibility profile targets and require explicit handling of unknown RGP major versions.

None of these questions requires modifying `pems/1`. They are design-freeze questions for a separately authorized PEMS/2 tranche.

## Recommended next gate

The Project Engineering Steward and owner should decide whether to authorize a **PEMS/2 semantic-contract design tranche** based on this disposition. If authorized, that tranche should produce only successor normative schemas, migration rules, RGP compatibility fixtures, and admission/validation contracts before any canonical-memory migration is considered.
