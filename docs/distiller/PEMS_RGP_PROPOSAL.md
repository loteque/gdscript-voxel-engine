# Proposal: Native RGP Support in PEMS

## Audience

PEMS architect / Steward.

## Proposal

Extend the next compatible PEMS revision so Project Engineering Memory can preserve the full semantic content of the Reasoning Graph Protocol (RGP) rather than accepting only a lossy projection of RGP propositions into the current closed PEMS v1 ontology.

This proposal does not recommend weakening or silently mutating `pems/1`. PEMS v1 should remain frozen. The change should be designed as an explicit schema evolution.

## Motivation

The Reasoning Distiller work produced a small domain-independent proposition graph and then attempted to map it into PEMS v1.

That mapping exercise exposed a structural gap rather than merely an adapter inconvenience. PEMS v1 represents project entities and selected project-memory relationships well, but cannot natively preserve several reasoning concepts that are useful for explaining why project knowledge exists.

A durable project memory that preserves both domain records and their reasoning graph can answer not only:

> What is the current project state?

but also:

> Why is this believed, assumed, unresolved, or required, and what would invalidate it?

That is a substantial value increase for human and agent consumers of PEMS.

## RGP Core

RGP represents atomic propositions with these kinds:

- `observation`
- `decision`
- `assumption`
- `uncertainty`
- `claim`

Derivation is represented by a first-class `premise` relationship stored on the derived proposition.

General proposition relationships are:

- `supports`
- `contradicts`
- `depends_on`
- `supersedes`

Propositions and relations may carry typed provenance:

- `primary`
- `corroborating`
- `context`

Provenance identifiers are opaque external source references. Normative standing is derived from resolved source chains rather than duplicated on propositions.

The full current RGP contract is documented in `docs/distiller/RGP.md`.

## Evidence From the PEMS Mapping Exercise

The current PEMS v1 mapping is intentionally partial.

Mappings that preserve semantics reasonably well include:

- RGP `decision` to PEMS `decision` when domain admission requirements are satisfied;
- consequential RGP `uncertainty` to PEMS `unresolved_item`;
- RGP `premise` to PEMS `derived_from`;
- RGP `depends_on` to PEMS `depends_on`;
- established RGP supersession to PEMS supersession mechanisms.

The following RGP semantics cannot currently be represented losslessly in PEMS v1:

- generic `observation` propositions that are not naturally one of PEMS's domain records;
- generic `claim` propositions;
- `assumption` propositions;
- proposition-level `supports`;
- proposition-level `contradicts`;
- the distinction between `primary`, `corroborating`, and `context` provenance.

The current adapter therefore has to retain these cases provisionally rather than coerce them into semantically incorrect PEMS records. This is the correct behavior for PEMS v1, but it prevents PEMS from preserving the full reasoning graph.

## Recommended Architectural Direction

Treat RGP as a generic semantic layer that PEMS can contain or specialize, not as a replacement for the existing PEMS domain ontology.

Conceptually:

```text
PEMS domain graph
    project
    chat
    role
    requirement
    module
    validation
    branch
    pull request
    ...

RGP proposition graph
    observation
    decision
    assumption
    uncertainty
    claim
    premise
    supports
    contradicts
    depends_on
    supersedes
    provenance

                ↓ integrated memory graph

PEMS next revision
```

PEMS domain entities answer what project objects and governed states exist. RGP propositions answer what is asserted about them and how those assertions are grounded or related.

This separation avoids forcing every proposition to become a domain entity while also avoiding a second disconnected reasoning database.

## Suggested Schema Capabilities

The next PEMS revision should be able to preserve, at minimum:

1. **Generic proposition records**
   - stable canonical identity;
   - RGP proposition kind;
   - atomic statement;
   - premise references;
   - typed provenance references.

2. **RGP relations**
   - `supports`;
   - `contradicts`;
   - `depends_on`;
   - `supersedes`.

3. **Typed provenance roles**
   - primary;
   - corroborating;
   - context.

4. **Source-chain authority semantics**
   - retain PEMS source/source-observation infrastructure where useful;
   - do not add proposition-level authority merely to simplify querying;
   - normative standing should remain derivable from source identity and provenance paths.

5. **Admission lifecycle separation**
   - RGP proposition kind must remain independent from whether a candidate is provisional, admitted, rejected, current, historical, or superseded;
   - admission must not rewrite `assumption` into fact or `uncertainty` into resolved knowledge.

6. **Historical graph preservation**
   - contradiction and supersession should preserve earlier propositions and their provenance;
   - currentness should be a memory lifecycle concern rather than destructive graph rewriting.

## Compatibility Constraints

- Keep `pems/1` immutable.
- Introduce RGP support only through a versioned PEMS evolution.
- Existing PEMS domain records should not be forced to become RGP propositions.
- Existing PEMS relations should remain available where they encode domain relationships not represented by RGP.
- RGP semantics should not be approximated by overloaded `data.qualifier` strings.
- Existing source and source-observation concepts should be reused where their semantics align rather than duplicated.
- Migration should be additive where practical: a valid PEMS v1 graph should have a deterministic representation in the successor schema.

## Why Native Integration Is Preferable to a Sidecar

A sidecar reasoning store would avoid changing PEMS but creates a second identity, lifecycle, provenance, and reconciliation boundary. That would make queries such as "why does this requirement exist?" dependent on cross-store joins and duplicated canonical identity rules.

Native integration allows one canonical memory graph while preserving a clean distinction between domain entities and propositions.

The cost is a broader PEMS ontology and a schema-version migration. Given the demonstrated semantic loss in the current adapter, that cost appears justified enough to warrant architectural evaluation.

## Non-Goals

This proposal does not ask PEMS to:

- store hidden model chain-of-thought;
- encode free-form reasoning narratives;
- automatically admit agent output as canonical truth;
- perform automatic causal inference;
- make RGP engineering-specific;
- replace domain-specific PEMS records with generic propositions;
- resolve contradictions automatically.

## Questions for the PEMS Architect

1. Should RGP propositions become a first-class PEMS record family, or should PEMS introduce a more general extensible semantic-record mechanism that RGP specializes?
2. Should `premise` remain a proposition-local reference in PEMS or normalize to a canonical relation such as `derived_from`?
3. Can the existing PEMS `source` / `source_observation` model cleanly back RGP's external provenance resolver while preserving primary/corroborating/context roles?
4. Should RGP `supersedes` share PEMS lifecycle supersession machinery or remain a proposition relation that drives lifecycle policy separately?
5. What successor semantic version best communicates the compatibility boundary?
6. Can generic RGP propositions coexist with domain records without creating ambiguous duplicate representations of decisions and unresolved items?

## Requested Outcome

Please evaluate RGP as a candidate first-class semantic extension to PEMS and propose the smallest coherent successor design that can preserve the full RGP graph without weakening PEMS v1's authority, provenance, lifecycle, and historical-integrity guarantees.

The preferred outcome is not necessarily direct adoption of the exact current RGP serialization. The important requirement is semantic preservation: PEMS should be capable of retaining the proposition kinds, premise graph, general reasoning relations, and typed provenance roles represented by RGP.