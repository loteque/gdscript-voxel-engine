# Provenance-Quality Distiller Evaluation

Date: 2026-08-15

## Method

Five separated distillation passes were performed over each of the five provenance evaluation cases using `docs/distiller/DIRECTIVE.md` and scored with `PROVENANCE_SCORING.md` against `provenance-expected.yaml`.

As with the earlier evaluations, these were repeated passes by the same model in one project session, not independently instantiated agent processes or cross-model runs. The results therefore test directive pressure and output stability, not cross-agent generalization.

## Aggregate Results

| Case | Accepted passes | Score range | Primary variance |
| --- | ---: | ---: | --- |
| `direct-test-over-chat` | 5 / 5 | 17–18 / 18 | Whether the implementation commit is retained alongside the passing test result |
| `owner-rule-over-agent-summary` | 5 / 5 | 18 / 18 | Minimal variance; owner authority and source origin remained stable |
| `conclusion-upstream-provenance` | 4 / 5 | 14–18 / 18 | One pass retained the broad chat summary alongside direct validation evidence and lost Source Specificity under the strict threshold |
| `conflicting-specific-sources` | 5 / 5 | 17–18 / 18 | Whether the safe synthesis is represented as `conclusion` or `uncertainty`; both direct observations remained present |
| `specific-file-over-repository-summary` | 5 / 5 | 16–18 / 18 | Preference varied between the implementation file alone and file + cleanup commit |

Overall: **24 / 25 case-runs met the current provenance acceptance threshold. No hard failures were observed.**

## Stable Findings

### Strong direct evidence usually displaces broad chat context

When a direct test result, repository file, workflow run, manual validation result, or owner instruction was supplied, repeated passes generally selected it instead of broad chat summaries.

This is especially strong in two cases:

- `direct-test-over-chat`: the passing test result was consistently primary support for the observed reload behavior.
- `owner-rule-over-agent-summary`: the owner instruction was consistently treated as the origin of the validation requirement; the agent summary was not promoted into authority.

The directive's provenance-strength ordering appears effective.

### Authority and provenance source class remain distinct

The owner-rule case showed that repository implementation evidence can corroborate a requirement without becoming the source of the requirement itself.

This distinction remained stable across all five passes:

```text
owner instruction -> authority / origin of governed requirement
repository validation scene -> corroborating implementation evidence
agent summary -> contextual only
```

This is an important result because provenance quality is not merely about immutability; source *role* matters.

### Derived conclusions retain upstream evidence

The experimental `conclusion` type materially improved the validation case. Four of five passes represented the scoped synthesis directly and attached at least one direct upstream validation source.

The strongest outputs used the complete direct validation set:

```text
headless validation pass
published workflow success
manual Integration Preview success
        ↓ supports
conclusion: required validation surfaces exercised successfully for tested revision
```

No pass broadened the conclusion into universal correctness, all-platform correctness, or future-revision correctness.

### Conflicting direct sources were preserved instead of flattened

All passes retained both:

- deployment workflow success; and
- missing RuntimeWorkloadExperimentUI in manual phone validation.

No pass treated deployment success as proof that UI startup was correct. No causal explanation was invented.

This confirms a useful provenance rule: when direct evidence addresses different layers of behavior, the distiller should preserve both rather than force one source to "win."

## Pressure Point: Flat Provenance References

The primary remaining problem is structural rather than epistemic.

The output contract currently gives each record one flat field:

```json
"provenance_refs": ["source-id"]
```

This field cannot distinguish why a source is present.

Repeated passes exposed at least four provenance roles:

- primary support;
- authority/origin;
- corroboration;
- contextual background.

For example, this source set is valid but ambiguous:

```text
source:test:reload-pass
source:commit:reload-test
source:chat:chunk-residency
```

A future reader cannot tell whether the chat is necessary evidence, merely context, or accidental citation residue.

This ambiguity caused the only threshold miss. One `conclusion-upstream-provenance` pass correctly retained direct evidence but also retained the broad chat summary in a way that made source priority unclear.

## Recommendation

Do not add more provenance-ranking prose to the directive. The ranking rule is already understood reasonably well.

Instead, the experimental protocol should distinguish provenance roles structurally.

A candidate shape for evaluation is:

```json
"provenance": {
  "primary": ["source:test:reload-pass"],
  "authority": [],
  "corroborating": ["source:commit:reload-test"],
  "context": []
}
```

For an owner-governed requirement:

```json
"provenance": {
  "primary": [],
  "authority": ["source:owner:validation-requirement"],
  "corroborating": ["source:implementation:validation-scene"],
  "context": []
}
```

For a derived conclusion:

```json
"provenance": {
  "primary": [
    "source:test:headless-pass",
    "source:workflow:web-deploy-success",
    "source:manual:web-demo-success"
  ],
  "authority": [],
  "corroborating": [],
  "context": []
}
```

The exact field names should remain experimental until evaluated.

## Secondary Finding: Source Strength Is Claim-Relative

The evaluation also shows that a source does not have one universal strength.

A commit can be direct evidence that code changed, but not direct evidence that the changed behavior works. A workflow run can directly establish deployment completion, but not runtime UI correctness. A repository file can establish current implementation structure, but not the origin of an owner requirement.

Therefore provenance ranking should eventually be evaluated relative to the proposition being supported, not only through a global source-type hierarchy.

This is important enough to preserve as a protocol requirement.

## Decision for Next Experiment

The provenance hypothesis is supported strongly enough to continue, but the flat provenance representation should not be frozen.

Next experiment:

1. introduce typed provenance roles experimentally;
2. rerun the five provenance cases;
3. test whether source-set noise decreases without increasing omission;
4. add one adversarial case where the same source is strong evidence for one proposition and weak evidence for another;
5. compare whether a fresh reader can reconstruct not only *where* a claim came from, but *why each source is attached*.

The current evidence supports moving toward a formal distillation protocol, but not yet freezing its provenance representation.
