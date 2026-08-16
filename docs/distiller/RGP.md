# Reasoning Graph Protocol (RGP)

## Purpose

The Reasoning Graph Protocol (RGP) is a domain-independent protocol for representing compact, provenance-backed symbolic reasoning as a graph of atomic propositions.

RGP is not an engineering ontology, project-memory schema, storage format, or record of hidden chain-of-thought. It represents externally supportable propositions and explicit relationships between them so reasoning can be preserved independently of conversational verbosity or application domain.

The Reasoning Distiller is one producer of candidate RGP graphs. PEMS is one potential consumer and durable-memory application of RGP.

## Core Schema

```json
{
  "records": [
    {
      "temp_id": "r1",
      "kind": "observation | decision | assumption | uncertainty | claim",
      "statement": "One atomic proposition.",
      "premise": ["record-id"],
      "provenance": {
        "primary": ["source-id"],
        "corroborating": ["source-id"],
        "context": ["source-id"]
      }
    }
  ],
  "relations": [
    {
      "from": "r1",
      "type": "supports | contradicts | depends_on | supersedes",
      "to": "r2",
      "provenance": {
        "primary": ["source-id"],
        "corroborating": ["source-id"],
        "context": ["source-id"]
      }
    }
  ]
}
```

Optional fields and collections are omitted when absent. RGP does not embed a `sources[]` registry. Provenance identifiers are opaque and resolve through the surrounding source system when source metadata is required.

## Proposition Kinds

- `observation`: empirically established, measured, inspected, tested, or otherwise observable state or behavior.
- `decision`: an explicit choice or accepted direction.
- `assumption`: a proposition relied upon without being established.
- `uncertainty`: an important unresolved question, unknown, or unverified condition.
- `claim`: a durable proposition established primarily by reasoning, interpretation, scope, compliance, or evidentiary relationships rather than observation alone.

## Derivation

Derivation is structural. A record with `premise` is derived from the referenced propositions. A record without `premise` is non-derived within the graph.

`premise` is not duplicated as a general relation. Premise references must resolve, must not self-reference, and premise chains must be acyclic.

## Provenance

Provenance relates propositions or relations to external sources:

- `primary`: directly establishes or externally grounds the proposition or relation;
- `corroborating`: independently strengthens it;
- `context`: explains or locates it without establishing it.

Source identifiers carry no semantics in their spelling. Source type, identity, and normative standing are resolved externally.

## General Relations

- `supports`: one proposition strengthens another without being constitutive of its derivation.
- `contradicts`: propositions are in material conflict.
- `depends_on`: continued validity, applicability, or revision of one proposition is conditional on another.
- `supersedes`: one proposition replaces another while preserving historical traceability.

## Core Invariants

- propositions are atomic;
- a non-derived observation requires primary provenance;
- derived observations may be grounded through premises;
- premise references are graph references, not provenance;
- provenance references are external source references, not graph propositions;
- normative standing is derived from resolved source chains rather than stored on propositions;
- source-ID spelling is semantically opaque;
- relations are emitted only when supported;
- `null`, empty arrays, and empty objects are omitted;
- RGP itself does not grant canonical admission, authority, or truth.

## Application Boundary

RGP deliberately stops before domain-specific memory policy. Applications may extend or map RGP into richer domain ontologies, but should preserve RGP semantics rather than coercing unsupported propositions into nearby domain types.

The current project uses this separation:

```text
observable evidence
      ↓
Reasoning Distiller
      ↓
candidate RGP graph
      ↓
validation / reconciliation / admission
      ↓
PEMS project memory
```

RGP is intended to remain independently useful outside PEMS and outside engineering. Domain-specific extensions should build on the generic graph rather than narrowing the core protocol.