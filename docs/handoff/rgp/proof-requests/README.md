# RGP Admission Proof Requests

This directory contains immutable branch-local requests for read-only execution of the deterministic RGP admission proof on `project-chat-handoff`.

A request does not grant admission, choose canonical identity, resolve provenance, or authorize canonical installation. It only asks repository-native CI to execute an already Steward-authored admission transaction plan and emit proof artifacts.

Request contract:

```text
rgp-admission-proof-request/1
```

Required fields:

```json
{
  "contract": "rgp-admission-proof-request/1",
  "submission_path": "docs/handoff/rgp/submissions/<submission>.json",
  "plan_path": "docs/handoff/rgp/admission/transactions/<plan>.json",
  "base_path": "docs/project-chat-handoff.json",
  "evidence_key": "safe-artifact-key"
}
```

Each request JSON is immutable once committed. Corrections or retries that require changed request bytes use a new filename/evidence key. The workflow accepts exactly one newly added request JSON per triggering commit and retains read-only repository permissions.
