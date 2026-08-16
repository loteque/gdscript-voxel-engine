# Admission Contract Evaluation — 2026-08-15

## Scope

Pressure-test the initial admission contract against ten lifecycle cases before implementing PEMS mapping or automated admission.

## Result

The contract preserved the intended distinctions across all ten cases without requiring a change to the distillation ontology.

Key outcomes:

- structural validity remained necessary but insufficient for admission;
- duplicate candidates reconciled to existing canonical identity rather than producing duplicate memory;
- unresolved required provenance prevented canonical admission as if grounding were known;
- conflicting propositions remained explicit instead of being silently overwritten;
- derived records with non-canonical premises required transactional admission or remained provisional;
- consequential uncertainties and assumptions remained admissible without semantic promotion;
- normative standing could not be created by admission when the authoritative source chain was absent;
- explicit supersession preserved historical records;
- recency alone did not establish supersession.

## Important Design Consequence

Admission outcome is lifecycle metadata, not proposition semantics. `admitted`, `provisional`, and `rejected` must therefore remain outside the distillation record schema.

The admission layer should operate transactionally over connected candidate subgraphs when premise or relation integrity requires multiple identities to be resolved together.

## Recommendation

Accept `docs/distiller/ADMISSION.md` as the initial admission contract and proceed to PEMS mapping/reconciliation design. Do not implement automatic admission policy yet; shadow operation should first establish which candidate classes can be safely admitted deterministically.
