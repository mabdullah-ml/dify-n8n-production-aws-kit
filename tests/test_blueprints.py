"""Unit tests for Dify DSL & n8n JSON enterprise workflow blueprint validation."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.validate_blueprints import validate_directory, validate_n8n_json

BLUEPRINTS_DIR = Path(__file__).resolve().parents[1] / "blueprints"


class TestBlueprintValidator(unittest.TestCase):
    def test_all_shipped_blueprints_pass_validation(self) -> None:
        checked, errors = validate_directory(BLUEPRINTS_DIR)
        self.assertGreaterEqual(checked, 4)
        self.assertEqual(errors, [])

    def test_secret_leak_in_workflow_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / "leaked.json"
            bad.write_text(
                '{"name":"Bad","nodes":[{"id":"1"},{"id":"2"}],"connections":{},"key":"AKIA1234567890ABCDEF"}',
                encoding="utf-8",
            )
            errors = validate_n8n_json(bad)
            self.assertTrue(any("hardcoded secret" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
