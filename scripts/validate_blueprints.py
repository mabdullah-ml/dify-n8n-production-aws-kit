"""Zero-dependency validator for Dify DSL YAML and n8n JSON enterprise workflow blueprints."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SECRET_RE = re.compile(r"(ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,})")


def validate_dify_yaml(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    errors: list[str] = []
    for required in ("app:", "name:", "mode:", "workflow:", "nodes:", "edges:"):
        if required not in text:
            errors.append(f"{path.name}: missing required Dify DSL key '{required}'")
    if SECRET_RE.search(text):
        errors.append(f"{path.name}: potential hardcoded secret detected")
    return errors


def validate_n8n_json(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    errors: list[str] = []
    if SECRET_RE.search(text):
        errors.append(f"{path.name}: potential hardcoded secret detected")
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        return [f"{path.name}: invalid JSON ({exc})"]

    for field in ("name", "nodes", "connections"):
        if field not in data:
            errors.append(f"{path.name}: missing top-level field '{field}'")
    nodes = data.get("nodes", [])
    if not isinstance(nodes, list) or len(nodes) < 2:
        errors.append(f"{path.name}: workflow must define at least 2 nodes")
    return errors


def validate_directory(root: Path) -> tuple[int, list[str]]:
    checked = 0
    errors: list[str] = []
    for yml in sorted(root.rglob("*.yml")):
        checked += 1
        errors.extend(validate_dify_yaml(yml))
    for js in sorted(root.rglob("*.json")):
        checked += 1
        errors.extend(validate_n8n_json(js))
    return checked, errors


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    target = Path(args[0]) if args else Path("blueprints")
    checked, errors = validate_directory(target)
    if errors:
        for err in errors:
            print(f"ERROR: {err}")
        return 1
    print(f"Validated {checked} Dify/n8n blueprints cleanly with 0 errors.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
