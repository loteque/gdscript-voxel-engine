# PEMS Architecture Review Request: Native RGP Support

## Recipient Role

Project Engineering Steward / PEMS architect.

## Request

Review `docs/distiller/PEMS_RGP_PROPOSAL.md` and the supporting RGP artifacts as an architecture proposal for the next versioned evolution of PEMS.

The proposal asks whether PEMS should gain native semantic support for the full Reasoning Graph Protocol (RGP), including generic propositions, premise derivation, proposition relations, and typed provenance roles, while preserving the frozen `pems/1` contract.

## Required Inputs

- `docs/distiller/RGP.md`
- `docs/distiller/PEMS_RGP_PROPOSAL.md`
- `docs/distiller/PEMS_MAPPING.md`
- `docs/distiller/ADMISSION.md`
- `docs/distiller/evaluation/pems-mapping-cases.yaml`
- `docs/distiller/evaluation/results/2026-08-15-pems-mapping-reconciliation-evaluation.md`

## Requested Analysis

Evaluate:

1. whether the demonstrated mapping losses justify a PEMS schema evolution;
2. whether RGP should become a first-class PEMS proposition family or be supported through a more general extension mechanism;
3. how RGP premise, supports, contradicts, depends_on, and supersedes semantics should coexist with existing PEMS relations and lifecycle mechanisms;
4. how RGP typed provenance should reuse PEMS source/source-observation infrastructure;
5. how to avoid duplicate semantic representations for decisions and unresolved items;
6. the smallest coherent successor contract that preserves full RGP meaning while keeping `pems/1` frozen;
7. migration, compatibility, validation, and admission implications.

## Constraints

- Do not modify `pems/1` in place.
- Do not weaken existing PEMS provenance, historical-preservation, identity, or authority guarantees.
- Do not coerce unsupported RGP concepts into semantically adjacent PEMS v1 types.
- Do not treat RGP admission as automatic truth or authority.
- RGP must remain domain-independent.

## Expected Output

Produce an architecture assessment with one of these dispositions:

- accept direction and propose successor PEMS design;
- accept problem but recommend an alternate integration architecture;
- reject with concrete semantic or lifecycle reasons.

Record unresolved design questions explicitly.