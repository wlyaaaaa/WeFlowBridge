import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class ProjectContractTests(unittest.TestCase):
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

        self.assertIn("docs/ai_consumer_contract.md", readme)
        self.assertIn("docs/privacy_boundary.md", readme)
        self.assertIn("docs/ai_consumer_contract.md", agents)
        self.assertIn("docs/privacy_boundary.md", agents)


if __name__ == "__main__":
    unittest.main()
