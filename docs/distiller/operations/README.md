# Distiller Operations Dashboard

The operations dashboard is a read-only view over existing Distiller/RGP evidence and GitHub Actions state.

## Authority boundary

The dashboard has no reconciliation or admission authority. It does not mutate candidate RGP, Steward reconciliation plans, canonical PEMS/COVE, dispositions, or admission state.

Authority remains:

- Distiller: candidate production only;
- Project Engineering Steward: semantic reconciliation and admission authority;
- deterministic workflow: proof/persist/install execution only.

Dashboard statuses are derived observations. They never advance an item through the pipeline.

## Pipeline states

The repository snapshot derives these states for each RGP submission:

- `waiting_steward`: submission exists but no Steward reconciliation transaction exists;
- `waiting_execution`: Steward reconciliation exists but no execution request exists;
- `execution_requested`: execution request exists but no persisted proof evidence exists;
- `proof_persisted`: proof evidence exists but no immutable disposition was found;
- `disposed`: an immutable disposition references the submission.

GitHub Actions state is overlaid in the browser to expose currently queued/in-progress/recent workflow runs. That overlay is informational and does not alter the repository-derived state.

## Metrics

The generated snapshot reports:

- submissions by derived pipeline state;
- total Steward reconciliation plans and execution requests;
- persisted proof bundles and dispositions;
- canonical PEMS record/relation counts;
- proof transaction totals for new, reused, and updated records/relations;
- validator/test PASS/FAIL lines extracted from persisted evidence;
- retry/correction pressure from multiple plans or requests for one submission.

## Publication

`.github/workflows/distiller-operations-dashboard.yml` builds `data.json`, tests its invariants, updates only `/operations/` in the existing `gh-pages` archive, and deploys the full archive through GitHub Pages.

The static UI lives in `docs/distiller/operations/site/` and is deliberately dependency-free.
