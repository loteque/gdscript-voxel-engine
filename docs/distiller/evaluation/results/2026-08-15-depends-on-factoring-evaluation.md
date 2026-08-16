# Depends-On Factoring Evaluation

Date: 2026-08-15

## Question

Can the `depends_on` relation be removed and represented without semantic loss by `premise`, `supports`, `supersedes`, or no relation?

## Method

Eight pressure cases were evaluated across five independent classification passes each (40 total decisions). Cases covered runtime contracts, configuration applicability, derivational evidence, decision support, policy supersession, platform-conditional validity, schema compatibility, and a causal-overreach control.

The candidate factoring rules were:

- use `premise` when one proposition participates directly in deriving another;
- use `supports` when one proposition strengthens another without being constitutive;
- use `supersedes` when one proposition replaces another;
- omit a relation when the evidence does not establish one;
- remove `depends_on` only if all conditional-validity cases can be represented without changing their meaning.

## Result

40/40 classifications preserved the expected distinction.

The `depends_on` cases could not be replaced cleanly by neighboring constructs:

- `premise` overstates inference: a runtime contract can be a condition for continued validity without being evidence from which the dependent proposition was derived;
- `supports` understates conditionality: support can disappear while the supported proposition remains valid, whereas a dependency identifies a condition whose change can invalidate or require revision of the dependent proposition;
- `supersedes` expresses replacement, not ongoing conditional validity;
- omission discards a durable relationship useful for impact analysis.

A practical definition that survived the pressure cases is:

> `A depends_on B` when a change to B can make A invalid, inapplicable, or require A to be revised, even though A is not inferred from B.

This is especially useful for architectural contracts, environment assumptions, compatibility constraints, and configuration-dependent validity.

## Decision

Keep `depends_on` as a first-class general relation.

No production schema change is recommended from this evaluation.
