"""Static checks for persistent Pi routing; no model calls or runtime writes."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ModelRoutingTests(unittest.TestCase):
    def test_model_ids_and_failure_routing(self):
        text = (ROOT / "config/agents/skills/_shared/model-routing.md").read_text()
        for model in ("gpt-5.6-luna", "gpt-5.6-terra", "gpt-5.6-sol", "gpt-6-astra"):
            self.assertIn(f"`openai-codex/{model}`", text)
        self.assertIn("Luna → Terra → Sol → Astra", text)
        self.assertIn("Keep the failed attempt's thinking level unchanged", text)
        self.assertIn("At Astra, stay on Astra", text)
        self.assertIn("existing retry limits still apply", text)
        self.assertNotIn("previously failed task", text)

    def test_explicit_launch_example(self):
        text = (ROOT / "config/agents/skills/_shared/model-routing.md").read_text()
        example = json.loads(re.search(r"```json\n(.*?)\n```", text, re.S).group(1))
        self.assertEqual(example["model"], "openai-codex/gpt-5.6-luna:medium")
        self.assertEqual(example["context"], "fresh")
        self.assertIn("new launch, not `resume`", text)
        self.assertIn("not hard runtime enforcement", text)

    def test_always_loaded_rules_reference_policy(self):
        rules = (ROOT / "config/agents/GLOBAL_RULES.md").read_text()
        self.assertIn("~/.agents/skills/_shared/model-routing.md", rules)
        self.assertIn("takes precedence over skill-local model/thinking defaults", rules)
        deployment = (ROOT / "docs/deployment.md").read_text()
        self.assertIn("Pi `~/.pi/agent/APPEND_SYSTEM.md` loads same text", deployment)


if __name__ == "__main__":
    unittest.main()
