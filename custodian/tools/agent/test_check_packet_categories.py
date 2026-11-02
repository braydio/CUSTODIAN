#!/usr/bin/env python3
"""Focused read-only packet category validator tests."""
import unittest
from check_packet_categories import check_packet


class CategoryHeaderTests(unittest.TestCase):
    def setUp(self):
        self.allowed = {"operator-actors", "agent-ops"}

    def test_new_packet_after_title_gap(self):
        text = "# Test\n\n- Packet schema: custodian.task_packet.v2\n- Workstream: test\n- Category: `operator-actors`\n\n## Steps\n"
        self.assertEqual(check_packet(text, self.allowed), "operator-actors")

    def test_reject_missing_header(self):
        with self.assertRaises(ValueError):
            check_packet("# Test\n\n- Workstream: test\n", self.allowed)

    def test_reject_invalid_id(self):
        with self.assertRaises(ValueError):
            check_packet("# Test\n\n- Category: `made-up`\n", self.allowed)

    def test_reject_duplicate_metadata(self):
        with self.assertRaises(ValueError):
            check_packet("# Test\n- Category: `agent-ops`\n- Category: `operator-actors`\n", self.allowed)

    def test_ignore_body_category(self):
        with self.assertRaises(ValueError):
            check_packet("# Test\n\n- Workstream: test\n\nSome body\n- Category: `agent-ops`\n", self.allowed)


if __name__ == "__main__":
    unittest.main()
