import unittest
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def read_json(relative_path: str) -> dict:
    return json.loads(read_text(relative_path))


class ProjectContractTests(unittest.TestCase):
    def test_project_manifest_exists_and_defines_ai_safe_boundaries(self):
        manifest = read_json("project_manifest.json")

        self.assertEqual(manifest["project"], "WeFlowBridge")
        self.assertEqual(manifest["visibility"], "public")
        self.assertEqual(manifest["role"], "provider_facing_adapter")
        self.assertEqual(manifest["closeout_status"], "ready_for_normal_maintenance")
        self.assertEqual(manifest["closeout_audit"], "docs/closeout_audit.md")
        self.assertTrue(manifest["no_raw_wechat_data"])
        self.assertEqual(
            manifest["ai_calling_layer"],
            r"E:\.agents\plugins\weflow-toolkit",
        )

        required_fields = set(manifest["required_output_envelope"])
        self.assertGreaterEqual(
            required_fields,
            {
                "current_library",
                "target_conversation",
                "talker",
                "time_window",
                "retry_count",
                "message_count",
                "lastTimestamp_matches_newest",
            },
        )

        forbidden = set(manifest["privacy_forbidden"])
        self.assertIn("raw_messages", forbidden)
        self.assertIn("database_files", forbidden)
        self.assertIn("conversation_screenshots", forbidden)

    def test_closeout_audit_exists_and_records_final_gate(self):
        text = read_text("docs/closeout_audit.md")

        required_terms = [
            "Closeout Audit",
            "ready_for_normal_maintenance",
            "No Raw WeChat Data",
            "Public Repository Boundary",
            "AI Consumer Boundary",
            "Non-Goals",
            "Reopen Triggers",
            "Verification Evidence",
            "Residual Risks",
            "2026-07-07",
        ]
        for term in required_terms:
            with self.subTest(term=term):
                self.assertIn(term, text)

    def test_ai_consumer_contract_exists_and_defines_required_fields(self):
        text = read_text("docs/ai_consumer_contract.md")

        required_terms = [
            "AI Consumer Contract",
            "current_library",
            "target_conversation",
            "talker",
            "time_window",
            "retry_count",
            "message_count",
            "lastTimestamp_matches_newest",
            "PersonalOS",
        ]
        for term in required_terms:
            with self.subTest(term=term):
                self.assertIn(term, text)

    def test_weflow_2673_ai_contract_is_documented(self):
        manifest = read_json("project_manifest.json")
        readme = read_text("README.md")
        agents = read_text("AGENTS.md")
        contract = read_text("docs/ai_consumer_contract.md")

        self.assertEqual(manifest["weflow_baseline"]["version"], "26.7.3")
        self.assertEqual(manifest["weflow_baseline"]["verified_on"], "2026-07-09")
        self.assertIn("ai_contract_version", manifest)
        self.assertEqual(manifest["ai_contract_version"], "v2")

        for text in (readme, agents):
            with self.subTest(document="entrypoint"):
                self.assertIn("26.7.3", text)
                self.assertIn("ChatLab Pull", text)
                self.assertIn("POST", text)

        required_contract_terms = [
            "AI Consumer Contract v2",
            "ChatLab Pull",
            "/api/v1/sessions/{id}/messages",
            "request_method",
            "endpoint_family",
            "sync_watermark",
            "replyToMessageId",
            "quote",
            "media_manifest",
        ]
        for term in required_contract_terms:
            with self.subTest(term=term):
                self.assertIn(term, contract)

    def test_ai_docs_prefer_v2_toolkit_and_chatlab_history(self):
        readme = read_text("README.md")
        agents = read_text("AGENTS.md")
        contract = read_text("docs/ai_consumer_contract.md")

        for text in (readme, agents):
            with self.subTest(document="entrypoint"):
                self.assertIn("weflow-toolkit v0.2+", text)
                self.assertIn("/api/v1/sessions/{id}/messages", text)
                self.assertIn("ChatLab Pull", text)
                self.assertIn("最新消息：不带 start/end", text)

        forbidden_preferred_examples = [
            "历史区间：显式 start/end",
            "历史区间显式 `start/end`",
            "chatlab=1&limit=20",
            "chatlab=1, \"limit\": 100",
            "safe local path hints",
            "api-media",
            "wxid_xxx/images",
            "mediaPath",
        ]
        for term in forbidden_preferred_examples:
            with self.subTest(term=term):
                self.assertNotIn(term, readme)
                self.assertNotIn(term, agents)
                self.assertNotIn(term, contract)

        self.assertIn("raw media paths", contract)
        self.assertIn("non-path", contract)

    def test_privacy_boundary_exists_and_blocks_private_material(self):
        text = read_text("docs/privacy_boundary.md")

        required_terms = [
            "Privacy Boundary",
            "public repository",
            ".env",
            "WEFLOW_TOKEN",
            "raw messages",
            "screenshots",
            "database",
            "exports/",
        ]
        for term in required_terms:
            with self.subTest(term=term):
                self.assertIn(term, text)

    def test_entry_docs_link_to_contracts(self):
        readme = read_text("README.md")
        agents = read_text("AGENTS.md")

        self.assertIn("project_manifest.json", readme)
        self.assertIn("project_manifest.json", agents)
        self.assertIn("docs/closeout_audit.md", readme)
        self.assertIn("docs/closeout_audit.md", agents)
        self.assertIn("docs/ai_consumer_contract.md", readme)
        self.assertIn("docs/privacy_boundary.md", readme)
        self.assertIn("docs/ai_consumer_contract.md", agents)
        self.assertIn("docs/privacy_boundary.md", agents)

    def test_gitignore_blocks_weflow_private_outputs(self):
        text = read_text(".gitignore")

        required_patterns = [
            ".env",
            ".env.*",
            "api-media/",
            "exports/",
            "dump/",
            "*.db",
            "*.sqlite",
            "*.sqlite3",
            "*.db-wal",
            "*.db-shm",
            "*.sqlite-wal",
            "*.sqlite-shm",
            "logs/",
        ]
        for pattern in required_patterns:
            with self.subTest(pattern=pattern):
                self.assertIn(pattern, text)


if __name__ == "__main__":
    unittest.main()
