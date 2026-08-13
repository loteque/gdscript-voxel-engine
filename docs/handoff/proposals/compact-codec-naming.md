# Compact Codec Naming Proposal

## Status

Proposed for independent review by the Engineering Knowledge Systems Architect.

## Context

The Architect's initial naming analysis recommends retaining `PEMS` (`Project Engineering Memory Schema`) as the project-domain semantic model name, while avoiding `JOLT` as the formal public/specification name for the domain-agnostic compact reversible JSON codec because of existing naming collisions and because `Linked Tokens` does not accurately describe the full representation contract.

The project owner agrees that a replacement codec name should be evaluated before the v1 representation contract is formalized.

## Preferred Name: COVE

**COVE: Canonical Object Value Encoding**

COVE is the project owner's preferred candidate.

Reasons for preference:

- `Canonical` reflects the requirement for deterministic representation from normalized input.
- `Object Value` describes structured JSON data without tying the codec to lexical/subword tokenization, a graph model, or one particular compression mechanism.
- `Encoding` accurately describes the layer's responsibility without implying that it owns PEMS semantics.
- The name remains compatible with dictionary encoding, stable references, enums, positional records, indexed values, and future representation improvements without making those mechanisms part of the codec's identity.
- It preserves the intended architectural boundary:

```text
Project information
        ↓
PEMS expanded semantic model
        ↓
normalization / canonicalization
        ↓
COVE
Canonical Object Value Encoding
        ↓
compact canonical JSON
```

COVE is a proposal, not an accepted specification name. It should be adopted only if it survives the Architect's architectural, terminology, namespace-collision, and future-compatibility analysis.

## Fallback Name: CCJ

**CCJ: Compact Canonical JSON**

If COVE fails architectural or naming analysis, CCJ is the project owner's preferred fallback candidate.

Reasons for retaining CCJ as the fallback:

- It is deliberately straightforward and descriptive.
- It strongly communicates that the canonical encoded artifact remains valid JSON.
- It avoids implying a particular internal compression technique.
- It provides a durable protocol-style identifier even if it is less distinctive than COVE.

Conceptually:

```text
PEMS 1.x
encoded using
CCJ 1.x
```

An artifact could identify independent semantic and codec contracts conceptually as:

```json
{
  "semantic": "pems/1",
  "codec": "ccj/1"
}
```

The exact metadata representation remains an architectural design question and is not established by this naming proposal.

## Requested Architectural Review

Evaluate COVE first and CCJ second. In particular:

1. Determine whether `Canonical Object Value Encoding` accurately describes the intended codec contract without creating misleading implementation expectations.
2. Check for material namespace or technology-name collisions that would make COVE unsuitable as a specification/protocol name.
3. Determine whether `Object Value` remains accurate across dictionaries, references, indexes, positional records, enums, and plausible future codec evolution.
4. Confirm that COVE preserves the boundary between PEMS semantics, normalization/canonicalization, and representation encoding.
5. If COVE is unsuitable, perform the same analysis for `Compact Canonical JSON` (CCJ).
6. Recommend adoption, rejection, refinement, or additional candidates as appropriate.

## Owner Preference

The current preference order is:

1. **COVE — Canonical Object Value Encoding**
2. **CCJ — Compact Canonical JSON**, if COVE fails architectural analysis

Neither name is considered accepted until architectural review is complete.