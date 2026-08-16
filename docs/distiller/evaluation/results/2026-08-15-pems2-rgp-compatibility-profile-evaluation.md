# PEMS/2 RGP Compatibility Profile Evaluation

Date: 2026-08-15
Branch: `pems-mapping-reconciliation`
Architect input: `ARCH-20260815T193249-0700-025`
Profile: `docs/distiller/PEMS2_RGP_COMPATIBILITY_PROFILE.md`
Cases: `docs/distiller/evaluation/pems2-rgp-compatibility-cases.yaml`

## Result

**20/20 compatibility pressure cases have an explicit semantics-preserving disposition.**

The seven Architect questions are resolved without modifying `pems/1`, inventing migration semantics, or broadening RGP through heuristic PEMS projections.

## Resolved decisions

1. **Domain-record proposition profile**
   - Only `decision` and unresolved `unresolved_item` are direct existing-domain RGP proposition nodes in the initial profile.
   - Other domain records require explicit propositions when reasoning about them.

2. **Resolved uncertainty export**
   - RGP export is snapshot-scoped.
   - Resolved items are not exported as current uncertainties.
   - Historical uncertainty is reconstructed from a historical snapshot where it was unresolved.

3. **Contradiction symmetry**
   - Semantic relation is symmetric.
   - Canonical storage uses one deterministically ordered edge.
   - Contradiction has no lifecycle or winner-selection effect.

4. **`depends_on` breadth**
   - PEMS/2 uses closed `dependency_kind` values: `conditional_validity`, `structural`, and migration-only `legacy_untyped`.
   - RGP maps only to `conditional_validity`.
   - Existing PEMS/1 dependencies migrate to `legacy_untyped`, avoiding invented semantics.

5. **Generic proposition refinement**
   - Stable kind/identity is never mutated.
   - A later precise domain record receives a new canonical identity.
   - Reviewed supersession may make the precise record current while preserving the generic historical proposition and its graph.

6. **Typed provenance atomicity**
   - Additive provenance is ordinary atomic enrichment when proposition semantics are unchanged.
   - `untyped` may move atomically to one established typed role under governance.
   - Typed-role changes/removals are semantic corrections and review-required.
   - Source changes create new immutable source observations.

7. **RGP version binding**
   - PEMS/2 compatibility profile targets `rgp/1`.
   - Unknown RGP majors fail closed.
   - PEMS and RGP version numbers remain independent.

## Important architectural effects

The `depends_on` decision is the main new PEMS/2 schema consequence beyond the Architect's initial sketch. PEMS/1 did not encode enough relation semantics to prove that every historical `depends_on` meant RGP conditional validity. A migration-only `legacy_untyped` profile preserves history without guessing, while native PEMS/2 can distinguish project structural dependency from RGP-compatible conditional validity.

The proposition-refinement decision deliberately rejects in-place kind mutation. Stable PEMS identity remains stable; improved domain precision is represented through a new admitted domain record plus reviewed supersession when established. This costs an additional historical record but avoids type-changing identity and preserves prior reasoning exactly.

Snapshot-scoped uncertainty export avoids turning a resolved historical question into a currently unresolved RGP proposition. It also avoids inventing a resolution proposition that RGP did not receive.

## Freeze recommendation

The seven questions no longer block a successor semantic-contract draft. The next Architect/Steward gate can now review the resolved profile as a whole and either:

- accept it as the PEMS/2 compatibility basis;
- request bounded changes to individual decisions; or
- identify a remaining contradiction with PEMS governance.

Implementation and canonical migration remain separately gated.