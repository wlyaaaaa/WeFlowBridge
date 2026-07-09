# Star-Optimized README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reposition WeFlowBridge as a public, star-friendly local-first WeChat API bridge for AI agents while preserving its privacy and contract-test guarantees.

**Architecture:** Keep the repository's verified AI integration files intact. Add a README positioning contract test, rewrite the README first screen and structure for public readers, and update GitHub repository metadata through `gh repo edit`.

**Tech Stack:** Markdown, Python `unittest`, PowerShell local CI, GitHub CLI.

## Global Constraints

- Public repository: never add tokens, `.env` values, raw messages, raw wxid/chatroom ids, database files, screenshots, exports, or media paths.
- Preserve WeFlow baseline: WeFlow `26.7.3`, verified on `2026-07-09`.
- Preserve AI contract links: `docs/openapi.yaml`, `schemas/ai-consumer-envelope.v2.schema.json`, `schemas/project-manifest.v1.schema.json`, `docs/ai_consumer_contract.md`, `docs/privacy_boundary.md`.
- README must lead with an external-facing English value proposition, then include Chinese context for local users.
- GitHub metadata must remove "私有" wording because the repository is public.

---

### Task 1: Add README Positioning Contract

**Files:**
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- Consumes: `README.md` text through existing `read_text()`.
- Produces: one new unittest method that fails until README has public positioning.

- [ ] **Step 1: Write the failing test**

Add this method to `ProjectContractTests`:

```python
    def test_readme_is_star_optimized_for_public_ai_agent_users(self):
        readme = read_text("README.md")

        required_terms = [
            "Local-first WeChat API bridge for AI agents",
            "Why this exists",
            "What you get",
            "What this repository never stores",
            "Quickstart",
            "OpenAPI",
            "JSON Schema",
            "privacy guardrails",
            "WeFlow 26.7.3",
        ]
        for term in required_terms:
            with self.subTest(term=term):
                self.assertIn(term, readme)

        first_screen = readme[:1800]
        self.assertIn("local-first", first_screen.lower())
        self.assertIn("AI agents", first_screen)
        self.assertIn("WeChat", first_screen)
        self.assertNotIn("私有，供 AI 集成", first_screen)
        self.assertNotIn("给我（主脑）", first_screen)
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
python -m unittest tests.test_project_contracts.ProjectContractTests.test_readme_is_star_optimized_for_public_ai_agent_users
```

Expected: FAIL because the current README starts as an internal Chinese note and does not contain the new public-positioning headings.

- [ ] **Step 3: Keep the test focused**

Do not add assertions about GitHub topics because topics live outside the working tree and are verified separately with `gh repo view`.

### Task 2: Rewrite README Public First Screen

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: existing endpoint, safety, quickstart, and contract details.
- Produces: a README that passes Task 1 while retaining required strings checked by existing tests.

- [ ] **Step 1: Replace the opening block**

Use an English-first opening:

```markdown
# WeFlowBridge

> Local-first WeChat API bridge for AI agents, built on WeFlow 26.7.3.

WeFlowBridge documents, verifies, and wraps WeFlow's local HTTP API so AI agents can safely read WeChat sessions, messages, contacts, group members, and Moments metadata without leaking tokens, raw transcripts, database files, or media paths.
```

- [ ] **Step 2: Add public-reader sections before the detailed API reference**

Add sections named exactly:

```markdown
## Why this exists
## What you get
## What this repository never stores
## Quickstart
## 中文说明
```

The `What you get` section must mention `OpenAPI`, `JSON Schema`, `privacy guardrails`, `contract tests`, and `metadata-first AI envelopes`.

- [ ] **Step 3: Preserve machine-contract links**

Keep links to:

```markdown
[docs/openapi.yaml](docs/openapi.yaml)
[schemas/ai-consumer-envelope.v2.schema.json](schemas/ai-consumer-envelope.v2.schema.json)
[schemas/project-manifest.v1.schema.json](schemas/project-manifest.v1.schema.json)
[docs/ai_consumer_contract.md](docs/ai_consumer_contract.md)
[docs/privacy_boundary.md](docs/privacy_boundary.md)
[docs/closeout_audit.md](docs/closeout_audit.md)
```

- [ ] **Step 4: Preserve existing technical constraints**

Keep these exact concepts in the README so existing tests continue to pass:

```text
26.7.3
ChatLab Pull
POST
weflow-toolkit v0.2+
/api/v1/sessions/{id}/messages
最新消息：不带 start/end
```

### Task 3: Update GitHub Repository Metadata

**Files:**
- No file changes.

**Interfaces:**
- Consumes: GitHub CLI authentication and public repository `wlyaaaaa/WeFlowBridge`.
- Produces: updated description and topics visible on GitHub.

- [ ] **Step 1: Update description and topics**

Run:

```powershell
gh repo edit wlyaaaaa/WeFlowBridge `
  --description "Local-first WeChat HTTP API bridge for AI agents: OpenAPI docs, safe metadata envelopes, probe scripts, and privacy guardrails for WeFlow 26.7.3." `
  --add-topic wechat `
  --add-topic weflow `
  --add-topic wechat-api `
  --add-topic chat-history `
  --add-topic ai-agents `
  --add-topic local-first `
  --add-topic privacy `
  --add-topic openapi `
  --add-topic chatlab `
  --add-topic windows `
  --add-topic powershell
```

- [ ] **Step 2: Verify metadata**

Run:

```powershell
gh repo view wlyaaaaa/WeFlowBridge --json description,repositoryTopics,visibility,stargazerCount,url
```

Expected: description has no `私有`, visibility is `PUBLIC`, topics include the 11 requested topics.

### Task 4: Verify, Commit, Push, and Record

**Files:**
- Modify: `README.md`
- Modify: `tests/test_project_contracts.py`
- Create: `docs/superpowers/plans/2026-07-09-star-optimized-readme.md`

**Interfaces:**
- Consumes: repository test suite and public-boundary scanner.
- Produces: pushed branch and public push record.

- [ ] **Step 1: Run focused README test**

Run:

```powershell
python -m unittest tests.test_project_contracts.ProjectContractTests.test_readme_is_star_optimized_for_public_ai_agent_users
```

Expected: OK.

- [ ] **Step 2: Run full contract tests**

Run:

```powershell
python -m unittest tests\test_project_contracts.py
```

Expected: 18 tests, OK.

- [ ] **Step 3: Run local CI**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1
```

Expected: unittest OK and public-boundary checks OK.

- [ ] **Step 4: Check whitespace and Git status**

Run:

```powershell
git diff --check
git status --short --branch
```

Expected: no whitespace errors, branch ahead with only README, tests, and plan changes.

- [ ] **Step 5: Commit and push**

Run:

```powershell
git add README.md tests/test_project_contracts.py docs/superpowers/plans/2026-07-09-star-optimized-readme.md
git commit -m "docs: optimize README for public AI users"
git push -u origin codex/weflowbridge-star-readme
```

- [ ] **Step 6: Record public push in total index**

Run `E:\GitHub总索引\tools\Add-PushRecord.ps1` with a public summary naming `wlyaaaaa/WeFlowBridge`, the branch, and the commit hash. Commit and push the total index if the record file changed.
