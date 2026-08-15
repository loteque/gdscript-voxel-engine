# Distiller Evaluation Corpus

This directory is the Phase 0 evaluation harness for the reasoning distiller.

The corpus uses completed voxel-engine work as fixed examples. Each case describes observable source material, the durable information a useful distillation should preserve, and failure modes it must avoid. These expectations are evaluation guidance, not canonical PEMS records.

## Procedure

1. Provide one case's source material to an agent using `../DIRECTIVE.md`.
2. Capture the structured distillation output without editing it.
3. Compare the result with `cases.yaml` and `expected.yaml`.
4. Score it using `SCORING.md`.
5. Record recurring omissions, inventions, duplication, provenance loss, or vocabulary pressure.
6. Do not modify PEMS automatically during Phase 0 or Phase 1.

## Corpus Selection

The initial cases intentionally cover different reasoning shapes:

- architectural ownership decision;
- offline/runtime separation;
- validation-driven project requirement;
- an investigation whose conclusion is narrower than the original hypothesis;
- unresolved behavior where the correct durable record is uncertainty rather than a fabricated explanation.

The source-of-truth material remains the referenced project records, repository evidence, and historical chat/source observations. Case descriptions are prompts for evaluation, not substitutes for source evidence.

## Success Signal

The prototype is promising if independent runs preserve the same high-value propositions and relationships, retain provenance, avoid invented reasoning, and remain substantially smaller than the original conversational material.