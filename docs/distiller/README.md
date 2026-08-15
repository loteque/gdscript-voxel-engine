# Reasoning Distiller

## Motivation

Engineering agents can perform substantial analysis while producing concise responses. The project should preserve the durable structure of important reasoning without requiring verbose chat transcripts to serve as the historical record.

A raw reasoning narrative is a poor project-memory format. It mixes durable conclusions with exploratory branches, repeated context, abandoned hypotheses, and conversational explanation. Conversely, storing only final decisions can erase useful information about evidence, assumptions, alternatives, uncertainty, and consequences.

The distiller exists to preserve the useful symbolic structure between those extremes.

## Intent

The distiller converts observable engineering work into candidate semantic records and relationships suitable for project memory.

It does not record, reconstruct, or claim access to an agent's hidden chain of thought. Its inputs are externally available task material such as owner instructions, repository observations, tool results, test and validation results, explicit alternatives, conclusions, decisions, artifacts, and unresolved questions.

The intended flow is:

```text
engineering work
      ↓
observable evidence and outcomes
      ↓
reasoning distillation
      ↓
candidate symbolic records and relations
      ↓
validation / reconciliation / admission
      ↓
project engineering memory
```

The conversational response is a separate projection. It should be optimized for the project owner and may remain concise even when the underlying work produces a richer durable record.

## Design Principles

1. Preserve the argument, not the monologue.
2. Distill only observable evidence and explicit outcomes; never reconstruct hidden reasoning.
3. Prefer atomic semantic records over prose reasoning blobs.
4. Represent reasoning primarily through typed relationships between records.
5. Preserve provenance for durable claims.
6. Distillation proposes memory; it does not automatically grant project authority.
7. Use language models where semantic interpretation is necessary and deterministic software for validation, identity, provenance integrity, reconciliation, and persistence.
8. Discard low-value activity. Opening a file is not memory; discovering a durable constraint may be.
9. Begin with a deliberately small vocabulary and expand from demonstrated need.
10. Keep the distiller independent of any single chat role, engineering domain, storage encoding, or conversational interface.

## Initial Symbolic Vocabulary

The first experiment should support only a small set of candidate record types:

- observation
- decision
- assumption
- uncertainty

Initial relations:

- supports
- contradicts
- depends_on
- supersedes
- validated_by

This vocabulary is intentionally incomplete. Alternatives, hypotheses, experiments, constraints, consequences, and other concepts should be added only when real project use demonstrates that the existing representation is insufficient.

## Relationship to PEMS and COVE

The distiller is upstream of project-memory admission. PEMS remains the semantic memory model, while COVE remains an encoding/storage concern. The distiller should not make either representation responsible for agent cognition.

A distillation result is best understood as a set of candidate semantic records with provenance. Existing or future reconciliation and admission policy determines whether those candidates become current project knowledge, remain provisional, conflict with existing knowledge, or are rejected.

## Success Criterion

A fresh agent should be able to answer a question such as "Why is this architecture this way?" by traversing durable project records and their evidence relationships, without needing to read the original chat transcript.

At the same time, ordinary project conversations should become shorter because the chat no longer has to double as the complete historical archive.
