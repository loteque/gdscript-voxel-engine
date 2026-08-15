# Distiller Evaluation Corpus

This directory is the Phase 0 evaluation harness for the reasoning distiller.

The corpus uses completed voxel-engine work as fixed examples. Each case describes observable source material, the durable information a useful distillation should preserve, and failure modes it must avoid. These expectations are evaluation guidance, not canonical PEMS records.

## Procedure

1. Provide one case's source material to an agent using `../DIRECTIVE.md`.
2. Capture the structured durable distillation output without editing it.
3. Compare the result with the corresponding expected-results file.
4. Score it using the relevant scoring document.
5. When needed for evaluation, request diagnostics separately from the durable output and record rejected candidates, rejection reasons, inventions, duplication, provenance loss, authority errors, or vocabulary pressure.
6. Do not admit evaluation diagnostics to project memory.
7. Do not modify PEMS automatically during Phase 0 or Phase 1.

A meaningful unresolved condition belongs in the durable graph as an `uncertainty`. Unsupported or low-value material is simply absent from durable output. Reasons for exclusion are diagnostics about distiller behavior, not project memory.

## Core Corpus

The initial corpus uses:

- `cases.yaml`
- `expected.yaml`
- `SCORING.md`

The cases intentionally cover different reasoning shapes:

- architectural ownership decision;
- offline/runtime separation;
- validation-driven project requirement;
- an investigation whose conclusion is narrower than the original hypothesis;
- unresolved behavior where the correct durable record is uncertainty rather than a fabricated explanation.

## Provenance Corpus

The provenance-quality experiment uses:

- `provenance-cases.yaml`
- `provenance-expected.yaml`
- `PROVENANCE_SCORING.md`

It tests whether the distiller:

- prefers specific immutable evidence over broad chat or summary context;
- derives authority from the correct source;
- preserves upstream evidence for derived conclusions;
- retains conflicting direct observations instead of falsely reconciling them;
- uses a minimal sufficient provenance set rather than attaching every valid source.

The source-of-truth material remains the referenced project records, repository evidence, and historical source observations. Case descriptions are prompts for evaluation, not substitutes for source evidence.

## Success Signal

The prototype is promising if independent runs preserve the same high-value propositions and relationships, retain the strongest available provenance, avoid invented reasoning, and remain substantially smaller than the original conversational material.