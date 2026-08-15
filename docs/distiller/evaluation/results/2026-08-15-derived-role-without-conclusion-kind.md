# Derived Role Without `conclusion` Kind

Date: 2026-08-15

## Purpose

Test whether the new separation between proposition kind and epistemic role makes the `conclusion` kind redundant.

The directive was changed so that derivedness is expressed only through `epistemic_role: derived`. The allowed proposition kinds are now:

- observation
- decision
- assumption
- uncertainty

The evaluation focused on the cases that previously created pressure for a `conclusion` kind.

## Cases Retested

### 1. Validation-evidence synthesis

Target proposition:

> The tested revision exercised the required validation surfaces successfully.

Evidence:

- headless validation passed;
- the published Integration Preview ran successfully;
- manual QA confirmed the expected behavior.

Five separated passes all retained the synthesis without using `conclusion`.

Observed representations:

- 4 / 5 used `kind: observation`, `epistemic_role: derived`, `authority: observed`;
- 1 / 5 used `kind: observation`, `epistemic_role: derived`, `authority: agent`.

All five preserved direct validation provenance and kept the statement scoped to the tested revision.

Finding: for empirical synthesis, `epistemic_role: derived` removes the need for a separate `conclusion` kind cleanly.

### 2. Resource-loading synthesis

Target shape:

> The measured loading evidence supports a scoped bottleneck finding without establishing universal behavior on unmeasured platforms or builds.

Five separated passes preserved the measured proposition and the unmeasured-platform uncertainty.

Observed representations:

- 5 / 5 used an `observation` with `epistemic_role: derived` for the measured synthesis;
- 5 / 5 retained a separate `uncertainty` with `epistemic_role: unresolved` for unmeasured environments.

No pass broadened the finding into a universal performance claim.

Finding: this was the original case that motivated `conclusion`; the new epistemic-role axis resolves its previous type pressure.

### 3. Deployment-success inference boundary

Target proposition:

> Deployment success does not establish runtime UI startup correctness.

Evidence:

- deployment workflow succeeded;
- manual phone validation showed the runtime UI missing.

This case remained less clean.

Observed representations:

- 3 / 5 used `kind: observation`, `epistemic_role: derived`, `authority: agent`;
- 1 / 5 omitted the synthesized inference and retained only the two direct observations plus unresolved UI state;
- 1 / 5 attempted to represent the inference as an `assumption` with `epistemic_role: derived`, which is semantically weak.

No pass falsely resolved the UI cause or treated deployment success as proof of runtime UI correctness.

Finding: removing `conclusion` does not recreate the original empirical-synthesis problem, but it exposes a narrower issue: some durable inferential statements are not naturally an observation, decision, assumption, or uncertainty.

## Aggregate Result

Across 15 case-runs:

- 14 / 15 preserved the intended durable synthesis;
- 0 used the removed `conclusion` kind;
- 0 produced a hard epistemic or provenance failure;
- empirical derived propositions were stable;
- meta-evidentiary / inferential propositions still create kind pressure.

## Interpretation

The evidence supports removing `conclusion` as a proposition kind.

The earlier evaluation was correctly detecting a missing representation for derivedness. Once `epistemic_role` became independent, the main reason for `conclusion` disappeared.

However, the remaining deployment-inference case suggests that the proposition-kind vocabulary may still be too narrow. The problem is not specifically a missing conclusion type. It is that some propositions are generic claims about what evidence warrants rather than observations, decisions, assumptions, or uncertainties.

## Recommendation

Keep `conclusion` removed.

Do not immediately add another semantic kind. First test two competing simplifications:

1. allow `kind` to be omitted for generic propositions whose epistemic role and relations carry the important semantics; or
2. introduce a minimal generic `claim` kind for durable propositions that do not fit a more specific kind.

The next evaluation should compare these options on inferential, contractual, empirical, and unresolved cases. Prefer omission of `kind` if it remains unambiguous, because the protocol is explicitly trying to avoid carrying fields that do not add information.

## Schema Status After Test

Current candidate kinds:

- observation
- decision
- assumption
- uncertainty

Current epistemic roles:

- axiom
- derived
- unresolved

`conclusion` remains removed from the experimental protocol.
