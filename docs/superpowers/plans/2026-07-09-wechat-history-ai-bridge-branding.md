# WeChat History AI Bridge Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reposition the public repository around the user-facing problem "微信聊天记录如何本地接入 AI" and rename the GitHub slug to `wechat-history-ai-bridge`.

**Architecture:** Keep `WeFlowBridge` as the internal compatibility name for scripts, schema titles, and local paths. Change the public display name, README first screen, GitHub repository slug, repository description, topics, and machine-readable repository field.

**Tech Stack:** Markdown, JSON, Python `unittest`, PowerShell local CI, GitHub CLI.

## Global Constraints

- Public repository: do not add tokens, `.env` values, raw messages, raw wxids/chatroom ids, databases, screenshots, exports, media payloads, or local media paths.
- Display name: `微信聊天记录 AI 本地桥（WeChat History AI Bridge）`.
- GitHub slug: `wechat-history-ai-bridge`.
- Internal compatibility name: preserve `WeFlowBridge` where it identifies the adapter, scripts, schema titles, or existing local path.
- GitHub description must be Chinese-first and mention `WeFlow`, `AI Agent`, `OpenAPI`, `脱敏 envelope`, `自检脚本`, and `隐私边界`.
- GitHub topics must include `wechat`, `wechat-history`, `wechat-chat-history`, `ai-agent`, `ai-agents`, `local-first`, `privacy`, `openapi`, `weflow`, `chatlab`, `windows`, and `powershell`.

---

### Task 1: Add Branding Contract Tests

**Files:**
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- Consumes: `README.md`, `project_manifest.json`, and `schemas/project-manifest.v1.schema.json`.
- Produces: tests that fail until the README is Chinese-first and the repository slug is updated.

- [ ] **Step 1: Replace the README positioning test**

Replace the old English-first star test with a Chinese-first test requiring:

```python
required_terms = [
    "微信聊天记录 AI 本地桥（WeChat History AI Bridge）",
    "想让 AI 安全读取、检索和总结本地微信聊天记录",
    "微信聊天记录怎么导出",
    "微信群聊天记录怎么总结",
    "WeFlow 负责本地读取微信数据",
    "WeFlowBridge 负责把它整理成 AI 友好的安全接口",
    "English: Local-first WeChat chat history bridge for AI agents, powered by WeFlow.",
]
```

- [ ] **Step 2: Add repository slug assertions**

Assert:

```python
self.assertEqual(manifest["repository"], "wlyaaaaa/wechat-history-ai-bridge")
self.assertEqual(schema["properties"]["repository"]["const"], "wlyaaaaa/wechat-history-ai-bridge")
```

Keep `manifest["project"] == "WeFlowBridge"` and schema title checks unchanged.

- [ ] **Step 3: Run focused tests and confirm RED**

Run:

```powershell
python -m unittest tests.test_project_contracts.ProjectContractTests.test_readme_targets_chinese_wechat_history_ai_users tests.test_project_contracts.ProjectContractTests.test_project_manifest_exists_and_defines_ai_safe_boundaries tests.test_project_contracts.ProjectContractTests.test_project_manifest_schema_tracks_current_manifest
```

Expected: FAIL before README/manifest/schema changes.

### Task 2: Update Public Branding Documents

**Files:**
- Modify: `README.md`
- Modify: `project_manifest.json`
- Modify: `schemas/project-manifest.v1.schema.json`
- Modify: `docs/privacy_boundary.md`

**Interfaces:**
- Consumes: current AI Integration 1.0 docs.
- Produces: Chinese-first public branding while keeping technical contracts stable.

- [ ] **Step 1: Rewrite README first screen**

Use this H1 and opening:

```markdown
# 微信聊天记录 AI 本地桥（WeChat History AI Bridge）

> 想让 AI 安全读取、检索和总结本地微信聊天记录？
> 本项目基于 WeFlow 26.7.3，把本地微信 HTTP API 整理成可验证、可脱敏、可集成的 AI 消费契约。

English: Local-first WeChat chat history bridge for AI agents, powered by WeFlow.
```

- [ ] **Step 2: Lead with user search intent**

Add a section that names user problems directly:

```markdown
很多人真正想找的是：
- 微信聊天记录怎么导出
- 微信聊天记录怎么给 AI 分析
- 微信群聊天记录怎么总结
- 微信聊天记录有没有本地 API
- 怎么不上传云端也能让 AI 读微信记录
```

- [ ] **Step 3: Explain WeFlowBridge as the middle layer**

Add:

```markdown
WeFlow 负责本地读取微信数据；WeFlowBridge 负责把它整理成 AI 友好的安全接口、OpenAPI、Schema、自检脚本和隐私边界。
```

- [ ] **Step 4: Update repository field and schema const**

Change:

```json
"repository": "wlyaaaaa/wechat-history-ai-bridge"
```

Do not rename local path or script names in this task.

### Task 3: Rename GitHub Repository and Tags

**Files:**
- No direct file changes.

**Interfaces:**
- Consumes: GitHub CLI authenticated access.
- Produces: public repository at `wlyaaaaa/wechat-history-ai-bridge` with Chinese-first description and search topics.

- [ ] **Step 1: Commit and push branch before default-branch merge**

Commit docs/tests first on branch `codex/wechat-history-ai-bridge-branding`.

- [ ] **Step 2: Fast-forward master and push**

Fast-forward local `master`, push it to the current remote, then rename the GitHub repo.

- [ ] **Step 3: Rename repo and set metadata**

Run:

```powershell
gh repo rename wechat-history-ai-bridge --repo wlyaaaaa/WeFlowBridge --yes
gh repo edit wlyaaaaa/wechat-history-ai-bridge `
  --description "微信聊天记录 AI 本地桥 / WeChat History AI Bridge：基于 WeFlow，把本地微信 HTTP API 整理成可给 AI Agent 安全读取的 OpenAPI、脱敏 envelope、自检脚本和隐私边界。" `
  --add-topic wechat `
  --add-topic wechat-history `
  --add-topic wechat-chat-history `
  --add-topic ai-agent `
  --add-topic ai-agents `
  --add-topic local-first `
  --add-topic privacy `
  --add-topic openapi `
  --add-topic weflow `
  --add-topic chatlab `
  --add-topic windows `
  --add-topic powershell
```

- [ ] **Step 4: Update local remotes**

Run in all local worktrees:

```powershell
git remote set-url origin https://github.com/wlyaaaaa/wechat-history-ai-bridge.git
```

### Task 4: Verify, Review, Record

**Files:**
- Modified docs/tests/schema files.

**Interfaces:**
- Consumes: local and remote CI.
- Produces: synced default branch and total-index push record.

- [ ] **Step 1: Run tests**

```powershell
python -m unittest tests\test_project_contracts.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1
git diff --check
```

- [ ] **Step 2: Request read-only review**

Ask a reviewer to check branding, repository slug consistency, and public-boundary safety.

- [ ] **Step 3: Verify GitHub metadata and Actions**

```powershell
gh repo view wlyaaaaa/wechat-history-ai-bridge --json nameWithOwner,description,repositoryTopics,visibility,url,defaultBranchRef
gh run list --repo wlyaaaaa/wechat-history-ai-bridge --workflow contract.yml --limit 3 --json status,conclusion,headSha,url
```

- [ ] **Step 4: Record push in total index**

Use `E:\GitHub总索引\tools\Add-PushRecord.ps1` for `wlyaaaaa/wechat-history-ai-bridge`, then push total index.
