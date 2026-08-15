# Provenance Evaluation Scoring

This evaluation tests whether the distiller preserves not merely valid provenance, but the strongest and most specific provenance available for each durable proposition.

## Dimensions

### 1. Source Specificity — 0 to 3

- 3: selects the strongest direct source available for the proposition.
- 2: selects a valid source but also relies unnecessarily on broader context.
- 1: relies mainly on broad context despite stronger direct evidence being supplied.
- 0: fabricates provenance or uses only indirect context when direct evidence exists.

### 2. Authority Fidelity — 0 to 3

- 3: authority is derived from the correct source class, especially explicit owner/governed sources.
- 2: authority is correct but provenance selection is slightly noisy.
- 1: authority origin is materially blurred.
- 0: agent interpretation or summary is promoted into owner/governed authority.

### 3. Derived-Proposition Traceability — 0 to 3

- 3: conclusions retain direct upstream evidence sufficient to reconstruct their support.
- 2: conclusion provenance is valid but omits a useful direct source.
- 1: conclusion is mostly supported through contextual summaries rather than upstream evidence.
- 0: conclusion has no meaningful supporting provenance.

### 4. Conflict Preservation — 0 to 3

- 3: conflicting direct observations remain independently represented and no false resolution is introduced.
- 2: conflict survives but one side is weakly represented.
- 1: the output strongly favors one source without justification.
- 0: conflicting direct evidence is silently discarded or falsely reconciled.

### 5. Minimal Sufficiency — 0 to 3

- 3: provenance set is compact and sufficient; unrelated valid sources are omitted.
- 2: one unnecessary contextual source is retained.
- 1: source lists are noisy enough to obscure which evidence actually supports the claim.
- 0: provenance becomes an undifferentiated source dump.

### 6. Scope Safety — 0 to 3

- 3: the proposition remains exactly within the scope established by its evidence.
- 2: wording is slightly broad but does not materially change truth.
- 1: scope expansion creates a meaningful ambiguity.
- 0: scoped evidence is converted into a universal or unsupported claim.

## Acceptance Threshold

A provenance case is acceptable when:

- no hard failure from `provenance-expected.yaml` occurs;
- Source Specificity, Authority Fidelity, and Scope Safety each score 3;
- total score is at least 15 / 18.

## Evaluation Procedure

Run each case repeatedly using `DIRECTIVE.md` and compare:

- selected provenance IDs;
- omitted provenance IDs;
- authority classification;
- conclusion support chains;
- conflict preservation;
- number of provenance references per record.

The evaluation should prefer a small correct source set over exhaustive citation. The goal is traceable engineering memory, not citation confetti.
