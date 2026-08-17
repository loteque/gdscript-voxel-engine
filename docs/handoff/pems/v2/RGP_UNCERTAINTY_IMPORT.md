# PEMS/2 RGP/1 Uncertainty Import Profile

## Status and authority

This is an additive normative compatibility profile for the adopted `pems/2` representation. It closes the representation gap identified by Steward disposition `RGPD-20260816T192600-0700-005`.

It does not change RGP semantics, canonical identity authority, provenance authority, `cove/1`, `jcs/1`, or canonical project-memory contents. It does not itself admit any RGP submission. The Project Engineering Steward remains the sole authority for semantic identity reconciliation and canonical admission.

## Normative rule

An RGP/1 record with `kind: "uncertainty"` imports to a PEMS/2 `unresolved_item`, not to a generic `claim`.

The deterministic semantic projection is:

| RGP/1 | PEMS/2 |
| --- | --- |
| `kind: "uncertainty"` | `kind: "unresolved_item"` |
| `statement` | `data.summary`, byte-for-byte as a JSON string value |
| unresolved status inherent in RGP uncertainty | `data.resolution_state: "open"` |
| admitted/current candidate state | `lifecycle: "current"` |
| typed provenance roles | same PEMS/2 provenance roles after Steward source-observation resolution |
| `premise` entries | `derived_from` relations from the imported unresolved item to the reconciled premise identities |
| `supports` | `supports` |
| `contradicts` | `contradicts`, with normal PEMS/2 canonical endpoint ordering |
| `depends_on` | `depends_on` with `dependency_kind: "conditional_validity"` |
| `supersedes` | `supersedes` |

`open` is the only lossless default resolution state for an imported RGP uncertainty. RGP/1 asserts that the proposition/question is unresolved but does not assert the stronger PEMS states `blocked` or `deferred`. Import tooling MUST NOT infer either stronger state.

An imported RGP uncertainty MUST NOT be coerced to `proposition_kind: "claim"`, `observation`, or `assumption`. It MUST NOT be converted to an accepted/rejected decision.

## Identity

The mapping above determines representation shape only. It does not determine canonical identity.

The Steward MUST reconcile the candidate against existing canonical `unresolved_item` identities. A tool may propose a candidate identity, but it MUST NOT decide whether an existing unresolved item is semantically identical, merely similar, superseded, contradicted, or distinct.

If no canonical identity is reused, the Steward may allocate a new `pems:unresolved_item:...` identity under the normal PEMS/2 admission rules.

## Provenance

RGP provenance identifiers remain opaque until resolved by the Steward. Import MUST preserve role distinctions (`primary`, `corroborating`, `context`) and MUST resolve them to canonical PEMS/2 `source_observation` identities before canonical admission.

No provenance role may be manufactured to make an uncertainty admissible.

## Premises and graph semantics

RGP permits `premise` on an uncertainty. PEMS/2 preserves that structure using ordinary `derived_from` relations even though `unresolved_item` does not carry the generic proposition `epistemic_role` field.

This is lossless because the derivation fact is represented by the relation itself. The imported unresolved item remains unresolved; derivation does not convert uncertainty into an established claim.

Connected graph admission remains atomic when partial persistence would break premise, contradiction, dependency, supersession, or epistemic meaning.

## Round-trip requirement

For the RGP/1 information domain, importing an uncertainty under this profile and exporting the resulting current/open PEMS/2 unresolved item MUST recover:

- RGP kind `uncertainty`;
- the exact statement;
- resolved provenance role structure;
- premise structure through `derived_from`;
- `supports`, `contradicts`, `depends_on`, and `supersedes` relation semantics.

PEMS-only state added after admission may make a later PEMS-to-RGP-to-PEMS round trip intentionally non-invertible. For example, changing an unresolved item from `open` to `blocked` carries PEMS state that RGP/1 uncertainty does not encode. That does not invalidate the RGP-to-PEMS import rule.

## Rejection conditions

Import MUST fail closed rather than coerce semantics when:

- the RGP major is not `rgp/1`;
- the uncertainty has unresolved provenance required by the applicable grounding/admission profile;
- a referenced premise or relation endpoint cannot be reconciled;
- canonical identity reconciliation detects collision or rebinding;
- connected-graph admission would require partial persistence that loses submitted semantics;
- any current PEMS/2 schema, provenance, relation, or canonicalization invariant would be violated.

## Trial-2 consequence

This profile removes the representation-only blocker identified for Trial-2 record `r4`. It does not admit Trial 2 and does not alter the Steward's epistemic disposition of any Trial-2 record. The Steward must independently reconsider the complete connected graph against current canonical state and current evidence.
