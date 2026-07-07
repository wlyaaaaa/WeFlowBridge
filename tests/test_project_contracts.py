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
