# External Source Resolution Evaluation

Date: 2026-08-15

## Question

Can proposition-level authority be recovered from provenance when the durable distillation graph contains only opaque source IDs and does not embed a `sources[]` collection?

## Setup

The durable candidate graphs contained only records, relations, premises, and provenance references.

An evaluation-only external registry mapped opaque IDs such as `s01` and `s02` to typed source entities. No semantics were inferred from source ID spelling.

Source contract under test:

```text
resolve(source_id) -> { source_id, type, locator }
```

Normative mapping under test:

```text
owner_instruction -> owner standing
governed_artifact -> governed standing
all other tested source types -> no normative standing by themselves
```

Corpus: `docs/distiller/evaluation/source-resolution-cases.yaml`

## Results

Five separated passes were evaluated across eight cases: 40 total authority-resolution decisions.

- 40 / 40 recovered the expected normative standing.
- 0 / 40 inferred authority from an opaque ID string.
- 0 / 40 promoted a repository file, chat summary, test result, workflow run, validation result, or benchmark result into normative authority.
- Derived propositions could trace normative standing through premise records to their authoritative provenance source without storing authority on the derived record.

A negative control with an unresolved source ID was treated as unresolved provenance rather than guessed authority.

## Findings

The durable graph does not need an embedded `sources[]` collection to recover authority, provided the surrounding memory system guarantees source resolution.

The necessary invariant is external to the graph:

```text
Every provenance source ID used for authority-sensitive interpretation must resolve to a typed source entity.
```

The source ID itself is opaque and carries no protocol semantics.

This cleanly factors normative standing out of proposition records:

```text
proposition
  -> provenance reference
  -> externally resolved source
  -> source type
  -> normative standing, when applicable
```

## Implication

The test supports removing proposition-level `authority` from the protocol. It also supports removing `provenance.authority`, because source type plus provenance role is sufficient to recover whether a source carries normative standing.

The resulting provenance vocabulary can be reduced to:

```text
primary
corroborating
context
```

No production schema change was made in this evaluation. The result should be treated as evidence for the next protocol revision, not as an already-adopted contract.

## Remaining requirement

Before removing authority fields, the source-resolution contract must be stated as a dependency of the durable graph validator or admission layer. A graph with an unresolved provenance ID must never infer authority from naming conventions or textual resemblance.
