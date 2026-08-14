# COVE v1 Phase 3 Contract and Validation

COVE (`cove/1`) is the domain-neutral structural codec layered beneath normalized semantic data. It encodes arbitrary supported JSON values without understanding PEMS record kinds, project concepts, provenance, terrain concepts, Steward admission, or runtime orchestration.

## Frozen structural contract

COVE v1 uses only:

1. global string interning;
2. deterministic object-shape factoring.

The artifact envelope is:

```json
{
  "c": "cove/1",
  "p": "<opaque required profile>",
  "s": null,
  "d": [],
  "h": [],
  "x": null
}
```

- `c`: independent codec identifier/version.
- `p`: opaque caller profile. The codec stores it and may enforce caller-supplied supported-profile allowlists, but never interprets its semantics.
- `s`: external deterministic serializer identifier or `null`. Phase 3 leaves it `null`; byte serialization belongs to Phase 4.
- `d`: every distinct string in the encoded input, including object keys and string values, sorted by bytewise UTF-8 lexicographic order.
- `h`: distinct object key sets represented as ascending string-dictionary indexes, deduplicated and lexicographically sorted.
- `x`: encoded root value.

Value tags are frozen as:

- raw JSON `null`, booleans, and finite numbers remain raw;
- `[0, dictionary_index]` is a string reference;
- `[1, ...encoded_items]` is an array;
- `[2, shape_index, ...encoded_values]` is an object, with values corresponding to that shape's key-index order.

COVE performs no Unicode normalization and rejects non-finite numbers, malformed envelopes, unsupported codec versions/profiles, noncanonical dictionaries/shapes, invalid references, malformed tags, and object arity mismatches.

## Phase 3 acceptance evidence

Phase 3 is COMPLETE only when all of the following are demonstrated by automated fixtures/tests:

- generic fixtures unrelated to PEMS round-trip exactly;
- malformed generic fixtures fail with their declared deterministic diagnostic codes;
- encoding is deterministic for semantically identical objects with different insertion/traversal order;
- repeated strings and repeated object shapes are actually interned/factored;
- empty arrays and objects, nested structures, primitives, and dictionary/reference boundaries round-trip;
- normalized PEMS passes only through the public normalized-data boundary and round-trips exactly through generic COVE;
- COVE source contains no PEMS record-kind or project-domain knowledge;
- no JCS implementation/selection, handoff migration, shadow migration, canonical-memory switch, agent runtime, or voxel-engine production behavior is introduced.

## Size observations

Phase 3 may report compact JSON character counts using ordinary minimal JSON serialization for directional observation only. Those counts are **not** canonical UTF-8 byte measurements and are not a compression acceptance threshold. Exact deterministic byte serialization is Phase 4 work.
