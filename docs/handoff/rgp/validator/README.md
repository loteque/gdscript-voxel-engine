# RGP Validator 1

`rgp-validator/1` is the deterministic structural validator for `rgp/1` candidate graphs used by the project handoff admission path.

Authoritative implementation:

```text
docs/handoff/rgp/validator/rgp_validator.py
```

The validator accepts either:

- a bare RGP graph containing `records` and optional `relations`; or
- an RGP Submission Protocol envelope containing `rgp_version == "rgp/1"` and `candidate_graph`.

It validates only deterministic RGP structural invariants. Passing validation does not imply truth, authority, semantic identity reconciliation, provenance resolution, or PEMS admission.

## Replay

```bash
python3 docs/handoff/rgp/validator/rgp_validator.py \
  docs/handoff/rgp/submissions/RGP-20260816T152100-0700-001.json
```

Exit code `0` means all supplied files passed. Exit code `1` means at least one supplied file failed or could not be read.

The version string emitted by `--version` is exactly:

```text
rgp-validator/1
```

The implementation is intentionally dependency-free so a Steward can replay it from an immutable repository commit with only Python 3.