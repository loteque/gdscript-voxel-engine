# Claim Factoring Evaluation

Date: 2026-08-15

## Question

Can `claim` be removed from the production record-kind vocabulary without losing semantic information?

## Method

Eight pressure cases were evaluated across five independent classification passes each. The cases targeted evidentiary boundaries, scoped validity, compliance judgments, architectural inference, logical non-entailment, derived empirical observations, uncertainty, and explicit project decisions.

The pressure condition required the proposition to be represented using only `observation`, `decision`, `assumption`, or `uncertainty`, without weakening, broadening, or changing what the proposition was about.

## Result

`claim` does not factor cleanly.

Across 40 classification decisions, the non-claim representation was acceptable for the control cases that were already naturally observations, uncertainties, or decisions. The pressure cases centered on evidentiary scope, compliance, and logical non-entailment repeatedly required either semantic distortion or unnatural use of `observation`.

Representative examples:

- `Successful deployment does not establish runtime UI startup correctness.` is about what one body of evidence entails about another proposition. It is not itself an observed runtime state.
- `Passing the headless test does not imply that the browser demo renders correctly.` expresses a logical non-entailment between propositions. No remaining kind captures that naturally.
- `This implementation satisfies the governed ownership contract.` is a compliance judgment unless a direct machine-checked compliance result is itself the proposition being recorded.

Derived empirical synthesis did not require `claim`; `Deserialization dominates the measured loading stages.` remains naturally an `observation` when grounded by empirical premises.

## Conclusion

Keep `claim`.

Its role is not "generic derived proposition." It is the semantic home for durable propositions whose content is primarily logical, interpretive, scope-based, evidentiary, or compliance-oriented rather than directly empirical, decisional, assumptive, or unresolved.

Removing `claim` would reduce the kind vocabulary by one entry but would push semantic classification into statement wording and downstream interpretation. That is counter to the purpose of symbolic distillation.

Production schema was not changed.
