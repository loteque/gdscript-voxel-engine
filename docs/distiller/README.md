# Reasoning Distiller

## Motivation

Agents can perform substantial analysis while producing concise responses. Durable reasoning should be preservable without requiring verbose chat transcripts to serve as the historical record.

A raw reasoning narrative is a poor memory format. It mixes durable conclusions with exploratory branches, repeated context, abandoned hypotheses, and conversational explanation. Conversely, storing only final decisions can erase useful information about evidence, assumptions, uncertainty, derivation, and consequences.

The distiller exists to preserve the useful symbolic structure between those extremes.

## Reasoning Graph Protocol

The symbolic protocol produced by the distiller is the **Reasoning Graph Protocol (RGP)**.

RGP is domain-independent. It represents atomic propositions, derivation, provenance, and explicit proposition relationships without depending on engineering, PEMS, COVE, a particular storage system, or a conversational interface.

The complete current protocol is documented in `docs/distiller/RGP.md`.

The Reasoning Distiller is one producer of candidate RGP graphs. PEMS is one potential consumer and durable-memory application of RGP.

## Intent

The distiller converts observable work into candidate RGP records and relationships suitable for validation, reconciliation, and eventual admission into an application memory system.

It does not record, reconstruct, or claim access to an agent's hidden chain of thought. Its inputs are externally available task material such as instructions, observations, tool results, tests, explicit alternatives, conclusions, decisions, artifacts, and unresolved questions.

The intended flow is:

```text
observable work and evidence
      ↓
reasoning distillation
      ↓
candidate RGP graph
      ↓
validation / reconciliation / admission
      ↓
application memory
```

The conversational response is a separate projection. It can remain concise even when the underlying work produces a richer durable reasoning graph.

## Design Principles

1. Preserve the argument, not the monologue.
2. Distill only observable evidence and explicit outcomes; never reconstruct hidden reasoning.
3. Prefer atomic semantic records over prose reasoning blobs.
4. Represent reasoning primarily through typed relationships between records.
5. Preserve provenance for durable claims.
6. Distillation proposes memory; it does not automatically grant authority or canonical admission.
7. Use language models where semantic interpretation is necessary and deterministic software for validation, identity, provenance integrity, reconciliation, and persistence.
8. Discard low-value activity.
9. Keep the core vocabulary small and expand only from demonstrated need.
10. Keep RGP independent of any single role, domain, storage encoding, or conversational interface.

## Relationship to PEMS and COVE

RGP is upstream of project-memory admission. PEMS currently provides the project's semantic memory model, while COVE remains an encoding/storage concern.

The current PEMS v1 mapping is intentionally partial because PEMS cannot losslessly represent every RGP proposition and relation. `docs/distiller/PEMS_MAPPING.md` documents that boundary. `docs/distiller/PEMS_RGP_PROPOSAL.md` proposes native RGP semantic support in a future PEMS revision while keeping `pems/1` frozen.

A distillation result is a candidate RGP graph. Reconciliation and admission policy determines whether its propositions become canonical application knowledge, remain provisional, conflict with existing knowledge, or are rejected.

## Success Criterion

A consumer should be able to reconstruct the durable structure explaining why important knowledge exists by traversing admitted propositions, relationships, and evidence without needing the original conversational transcript.

Ordinary conversations can then be optimized for communication rather than serving simultaneously as the complete historical archive.