"""Validate a character 3D contract against character_contract.v1.schema.json.

Dependency-free. Implements exactly the JSON Schema keywords the v1 schema uses:
type, const, enum, pattern, minLength, minimum, exclusiveMinimum, minItems, maxItems, items,
required, properties and additionalProperties. Any other keyword in the schema raises an error,
so the validator can never silently accept a constraint it does not check.

Usage:
  python3 -I custodian/tools/character3d/validate_contract.py <contract.json>
Exit status: 0 valid, 1 invalid, 2 usage or unreadable input.
"""
import json
import re
import sys
from pathlib import Path

SCHEMA_PATH = Path(__file__).resolve().parent / "contracts" / "character_contract.v1.schema.json"
IMPLEMENTED = {
    "$schema", "$id", "title", "description", "type", "const", "enum", "pattern", "minLength",
    "minimum", "exclusiveMinimum", "minItems", "maxItems", "items", "required", "properties",
    "additionalProperties",
}
TYPE_CHECKS = {
    "object": lambda v: isinstance(v, dict),
    "array": lambda v: isinstance(v, list),
    "string": lambda v: isinstance(v, str),
    "boolean": lambda v: isinstance(v, bool),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "null": lambda v: v is None,
}


def _check_keywords(schema: dict, where: str) -> None:
    unknown = set(schema) - IMPLEMENTED
    if unknown:
        raise ValueError(f"{where}: schema uses unimplemented keywords {sorted(unknown)}")


def validate(value, schema: dict, path: str = "$") -> list[str]:
    _check_keywords(schema, path)
    errors: list[str] = []
    if "type" in schema:
        types = schema["type"] if isinstance(schema["type"], list) else [schema["type"]]
        if not any(TYPE_CHECKS[t](value) for t in types):
            return [f"{path}: expected {'/'.join(types)}, got {type(value).__name__}"]
    if "const" in schema and value != schema["const"]:
        errors.append(f"{path}: must equal {json.dumps(schema['const'])}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: must be one of {schema['enum']}")
    if isinstance(value, str):
        if "pattern" in schema and not re.search(schema["pattern"], value):
            errors.append(f"{path}: does not match {schema['pattern']!r}")
        if "minLength" in schema and len(value) < schema["minLength"]:
            errors.append(f"{path}: shorter than {schema['minLength']}")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: below minimum {schema['minimum']}")
        if "exclusiveMinimum" in schema and value <= schema["exclusiveMinimum"]:
            errors.append(f"{path}: must be greater than {schema['exclusiveMinimum']}")
    if isinstance(value, list):
        if "minItems" in schema and len(value) < schema["minItems"]:
            errors.append(f"{path}: fewer than {schema['minItems']} items")
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            errors.append(f"{path}: more than {schema['maxItems']} items")
        if "items" in schema:
            for i, item in enumerate(value):
                errors += validate(item, schema["items"], f"{path}[{i}]")
    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{path}: missing required key {key!r}")
        props = schema.get("properties", {})
        extra = schema.get("additionalProperties", True)
        for key, item in value.items():
            if key in props:
                errors += validate(item, props[key], f"{path}.{key}")
            elif extra is False:
                errors.append(f"{path}: unexpected key {key!r}")
            elif isinstance(extra, dict):
                errors += validate(item, extra, f"{path}.{key}")
    return errors


def load_schema() -> dict:
    return json.loads(SCHEMA_PATH.read_text())


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__)
        return 2
    try:
        contract = json.loads(Path(argv[0]).read_text())
    except (OSError, json.JSONDecodeError) as exc:
        print(f"unreadable contract: {exc}")
        return 2
    errors = validate(contract, load_schema())
    if errors:
        print("INVALID")
        for e in errors:
            print(" ", e)
        return 1
    print("VALID", contract.get("character_id"), contract.get("status"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
