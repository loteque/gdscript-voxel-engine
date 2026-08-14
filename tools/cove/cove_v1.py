"""Deterministic domain-neutral COVE v1 structural codec.

COVE v1 compacts arbitrary normalized JSON values using two mechanisms only:
(1) a global string dictionary and (2) deterministic object-shape factoring.
It intentionally contains no PEMS-specific semantics.
"""

from __future__ import annotations

from dataclasses import dataclass
import math
from typing import Any, Iterable, Mapping, Sequence


COVE_VERSION = "cove/1"
TAG_STRING = 0
TAG_ARRAY = 1
TAG_OBJECT = 2


@dataclass(frozen=True)
class CoveDiagnostic:
    code: str
    path: str
    message: str


class CoveError(ValueError):
    """Raised when an input value or COVE artifact violates the v1 contract."""

    def __init__(self, code: str, path: str, message: str):
        super().__init__(f"{code} at {path}: {message}")
        self.diagnostic = CoveDiagnostic(code=code, path=path, message=message)


def _utf8_key(value: str) -> bytes:
    return value.encode("utf-8")


def _require_json_value(value: Any, path: str = "$") -> None:
    if value is None or isinstance(value, (str, bool)):
        return
    if isinstance(value, int) and not isinstance(value, bool):
        return
    if isinstance(value, float):
        if not math.isfinite(value):
            raise CoveError("COVE_NON_FINITE_NUMBER", path, "numbers must be finite")
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            _require_json_value(item, f"{path}[{index}]")
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if not isinstance(key, str):
                raise CoveError("COVE_NON_STRING_KEY", path, "JSON object keys must be strings")
            _require_json_value(item, f"{path}.{key}")
        return
    raise CoveError("COVE_UNSUPPORTED_VALUE", path, f"unsupported JSON value type: {type(value).__name__}")


def _collect_strings_and_shapes(value: Any, strings: set[str], key_sets: set[tuple[str, ...]]) -> None:
    if isinstance(value, str):
        strings.add(value)
        return
    if isinstance(value, list):
        for item in value:
            _collect_strings_and_shapes(item, strings, key_sets)
        return
    if isinstance(value, dict):
        keys = tuple(sorted(value.keys(), key=_utf8_key))
        key_sets.add(keys)
        strings.update(keys)
        for key in keys:
            _collect_strings_and_shapes(value[key], strings, key_sets)


def _shape_sort_key(shape: Sequence[int]) -> tuple[int, ...]:
    return tuple(shape)


def encode(value: Any, *, profile: str, serializer: str | None = None) -> dict[str, Any]:
    """Encode a normalized JSON value as one deterministic COVE v1 artifact.

    ``profile`` is opaque to COVE. The codec stores but never interprets it.
    ``serializer`` identifies an external byte serializer when one is selected;
    Phase 3 callers normally leave it as ``None``.
    """

    if not isinstance(profile, str) or not profile:
        raise CoveError("COVE_INVALID_PROFILE", "$.p", "profile must be a non-empty string")
    if serializer is not None and (not isinstance(serializer, str) or not serializer):
        raise CoveError("COVE_INVALID_SERIALIZER", "$.s", "serializer must be null or a non-empty string")

    _require_json_value(value)

    strings: set[str] = set()
    key_sets: set[tuple[str, ...]] = set()
    _collect_strings_and_shapes(value, strings, key_sets)

    dictionary = sorted(strings, key=_utf8_key)
    string_index = {item: index for index, item in enumerate(dictionary)}

    shape_set = {
        tuple(sorted((string_index[key] for key in keys)))
        for keys in key_sets
    }
    shapes = [list(shape) for shape in sorted(shape_set, key=_shape_sort_key)]
    shape_index = {tuple(shape): index for index, shape in enumerate(shapes)}

    def encode_value(item: Any) -> Any:
        if item is None or isinstance(item, bool):
            return item
        if isinstance(item, int) and not isinstance(item, bool):
            return item
        if isinstance(item, float):
            return item
        if isinstance(item, str):
            return [TAG_STRING, string_index[item]]
        if isinstance(item, list):
            return [TAG_ARRAY, *(encode_value(child) for child in item)]
        if isinstance(item, dict):
            key_indexes = tuple(sorted(string_index[key] for key in item.keys()))
            values = []
            for key_idx in key_indexes:
                key = dictionary[key_idx]
                values.append(encode_value(item[key]))
            return [TAG_OBJECT, shape_index[key_indexes], *values]
        raise AssertionError("validated JSON value reached unsupported branch")

    return {
        "c": COVE_VERSION,
        "p": profile,
        "s": serializer,
        "d": dictionary,
        "h": shapes,
        "x": encode_value(value),
    }


def _validate_dictionary(dictionary: Any) -> list[str]:
    if not isinstance(dictionary, list):
        raise CoveError("COVE_MALFORMED_DICTIONARY", "$.d", "dictionary must be an array")
    if any(not isinstance(item, str) for item in dictionary):
        raise CoveError("COVE_MALFORMED_DICTIONARY", "$.d", "dictionary entries must be strings")
    canonical = sorted(dictionary, key=_utf8_key)
    if dictionary != canonical:
        raise CoveError("COVE_DICTIONARY_ORDER", "$.d", "dictionary strings must be in bytewise UTF-8 order")
    if len(dictionary) != len(set(dictionary)):
        raise CoveError("COVE_DUPLICATE_STRING", "$.d", "dictionary strings must be unique")
    return dictionary


def _validate_shapes(shapes: Any, dictionary_size: int) -> list[list[int]]:
    if not isinstance(shapes, list):
        raise CoveError("COVE_MALFORMED_SHAPES", "$.h", "shape dictionary must be an array")

    normalized: list[list[int]] = []
    seen: set[tuple[int, ...]] = set()
    previous: tuple[int, ...] | None = None

    for shape_idx, shape in enumerate(shapes):
        path = f"$.h[{shape_idx}]"
        if not isinstance(shape, list):
            raise CoveError("COVE_MALFORMED_SHAPE", path, "shape must be an array")
        if any(not isinstance(index, int) or isinstance(index, bool) for index in shape):
            raise CoveError("COVE_MALFORMED_SHAPE", path, "shape entries must be integer dictionary indexes")
        if any(index < 0 or index >= dictionary_size for index in shape):
            raise CoveError("COVE_STRING_INDEX_RANGE", path, "shape contains out-of-range dictionary index")
        if shape != sorted(shape) or len(shape) != len(set(shape)):
            raise CoveError("COVE_SHAPE_KEY_ORDER", path, "shape key indexes must be strictly increasing")

        key = tuple(shape)
        if key in seen:
            raise CoveError("COVE_DUPLICATE_SHAPE", path, "shape dictionary entries must be unique")
        if previous is not None and previous >= key:
            raise CoveError("COVE_SHAPE_ORDER", path, "shapes must be lexicographically ordered")
        previous = key
        seen.add(key)
        normalized.append(shape)

    return normalized


def decode(
    artifact: Mapping[str, Any],
    *,
    supported_profiles: Iterable[str] | None = None,
) -> Any:
    """Decode and fully validate one COVE v1 artifact.

    When ``supported_profiles`` is provided, the opaque profile must be present
    in that caller-supplied set. COVE itself never interprets profile meaning.
    """

    if not isinstance(artifact, Mapping):
        raise CoveError("COVE_MALFORMED_ENVELOPE", "$", "artifact must be a JSON object")

    expected_fields = {"c", "p", "s", "d", "h", "x"}
    if set(artifact.keys()) != expected_fields:
        raise CoveError("COVE_MALFORMED_ENVELOPE", "$", "artifact must contain exactly c, p, s, d, h, x")

    codec = artifact["c"]
    if codec != COVE_VERSION:
        if isinstance(codec, str) and codec.startswith("cove/"):
            raise CoveError("COVE_UNSUPPORTED_VERSION", "$.c", f"unsupported codec version {codec!r}")
        raise CoveError("COVE_MALFORMED_VERSION", "$.c", "codec identifier must be cove/1")

    profile = artifact["p"]
    if not isinstance(profile, str) or not profile:
        raise CoveError("COVE_INVALID_PROFILE", "$.p", "profile must be a non-empty string")
    if supported_profiles is not None and profile not in set(supported_profiles):
        raise CoveError("COVE_UNSUPPORTED_PROFILE", "$.p", f"unsupported required profile {profile!r}")

    serializer = artifact["s"]
    if serializer is not None and (not isinstance(serializer, str) or not serializer):
        raise CoveError("COVE_INVALID_SERIALIZER", "$.s", "serializer must be null or a non-empty string")

    dictionary = _validate_dictionary(artifact["d"])
    shapes = _validate_shapes(artifact["h"], len(dictionary))

    def decode_value(item: Any, path: str) -> Any:
        if item is None or isinstance(item, bool):
            return item
        if isinstance(item, int) and not isinstance(item, bool):
            return item
        if isinstance(item, float):
            if not math.isfinite(item):
                raise CoveError("COVE_NON_FINITE_NUMBER", path, "numbers must be finite")
            return item
        if not isinstance(item, list):
            raise CoveError("COVE_MALFORMED_VALUE", path, "encoded complex values must be tagged arrays")
        if not item:
            raise CoveError("COVE_MALFORMED_TAG", path, "tagged array cannot be empty")
        tag = item[0]
        if not isinstance(tag, int) or isinstance(tag, bool):
            raise CoveError("COVE_MALFORMED_TAG", path, "tag must be an integer")

        if tag == TAG_STRING:
            if len(item) != 2:
                raise CoveError("COVE_TAG_ARITY", path, "string reference must have arity 2")
            index = item[1]
            if not isinstance(index, int) or isinstance(index, bool) or index < 0 or index >= len(dictionary):
                raise CoveError("COVE_STRING_INDEX_RANGE", path, "string dictionary index is out of range")
            return dictionary[index]

        if tag == TAG_ARRAY:
            return [decode_value(child, f"{path}[{index}]") for index, child in enumerate(item[1:])]

        if tag == TAG_OBJECT:
            if len(item) < 2:
                raise CoveError("COVE_TAG_ARITY", path, "object record requires a shape index")
            shape_idx = item[1]
            if not isinstance(shape_idx, int) or isinstance(shape_idx, bool) or shape_idx < 0 or shape_idx >= len(shapes):
                raise CoveError("COVE_SHAPE_INDEX_RANGE", path, "shape index is out of range")
            shape = shapes[shape_idx]
            encoded_values = item[2:]
            if len(encoded_values) != len(shape):
                raise CoveError("COVE_OBJECT_ARITY", path, "object value count does not match referenced shape")
            result: dict[str, Any] = {}
            for offset, key_idx in enumerate(shape):
                key = dictionary[key_idx]
                if key in result:
                    raise CoveError("COVE_DUPLICATE_OBJECT_KEY", path, "decoded object contains duplicate key")
                result[key] = decode_value(encoded_values[offset], f"{path}.{key}")
            return result

        raise CoveError("COVE_UNKNOWN_TAG", path, f"unknown COVE tag {tag}")

    return decode_value(artifact["x"], "$.x")


def measure_structural_json(value: Any, artifact: Mapping[str, Any]) -> dict[str, int]:
    """Return non-canonical compact-JSON character counts for observation only.

    This deliberately does not claim JCS/byte canonicality. Phase 4 owns exact
    deterministic byte serialization.
    """

    import json

    expanded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    compact = json.dumps(dict(artifact), ensure_ascii=False, separators=(",", ":"))
    return {"expanded_json_chars": len(expanded), "cove_json_chars": len(compact)}
