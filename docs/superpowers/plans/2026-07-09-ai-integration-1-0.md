# WeFlowBridge AI Integration 1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add machine-readable contracts, CI/local verification, metadata-only probing, docs links, and a release anchor so WeFlowBridge is complete as a public-safe AI integration baseline.

**Architecture:** Keep human docs, machine contracts, and runtime probes separate. `docs/openapi.yaml` describes HTTP API shape, `schemas/*.schema.json` validates AI/project metadata, `probe-weflow.ps1` emits optional metadata-only JSON, and tests/CI enforce public-safety boundaries without live WeFlow data.

**Tech Stack:** Python stdlib `unittest`, PowerShell 5.1+/7 parser-compatible scripts, GitHub Actions on `windows-latest`, YAML/JSON contract files.

## Global Constraints

- Repository is public; never commit `.env`, token values, raw messages, ChatLab exports, screenshots, databases, media payloads, or local media paths.
- WeFlow baseline is `26.7.3` / ProductVersion `26.7.3.0`, verified on `2026-07-09`.
- AI contract version is `v2`; latest reads use `/api/v1/messages` without `start/end`; historical/bulk reads prefer ChatLab Pull `/api/v1/sessions/{id}/messages`.
- No new runtime dependency is required for tests; use Python stdlib and PowerShell built-ins.
- CI must not run live WeFlow, launch GUI programs, register scheduled tasks, or write Windows autologin registry keys.
- All examples use placeholders or redacted values only.

---

### Task 1: Machine Contracts

**Files:**
- Create: `docs/openapi.yaml`
- Create: `schemas/ai-consumer-envelope.v2.schema.json`
- Create: `schemas/project-manifest.v1.schema.json`
- Create: `docs/examples/ai_consumer_envelope.example.json`
- Modify: `project_manifest.json`
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- Produces `project_manifest.json.machine_contracts.openapi = "docs/openapi.yaml"`.
- Produces `project_manifest.json.machine_contracts.ai_consumer_envelope_schema = "schemas/ai-consumer-envelope.v2.schema.json"`.
- Produces `project_manifest.json.machine_contracts.project_manifest_schema = "schemas/project-manifest.v1.schema.json"`.
- Produces `project_manifest.json.integration_readiness.status = "ai_integration_1_0_ready"`.

- [ ] **Step 1: Write failing tests**

Add tests to `tests/test_project_contracts.py` that load JSON/YAML-ish text with stdlib, assert the new contract files exist, assert key OpenAPI paths are present, assert schema required fields include v2 fields, assert the example contains no raw `wxid_`, `@chatroom`, `WEFLOW_TOKEN`, Windows media paths, or `mediaPath`.

- [ ] **Step 2: Run the target tests and see failure**

Run: `python -m unittest tests\test_project_contracts.py`

Expected: fail because `docs/openapi.yaml`, `schemas/*.schema.json`, and `docs/examples/ai_consumer_envelope.example.json` do not exist.

- [ ] **Step 3: Add machine contract files**

Create the OpenAPI file with paths for `/health`, `/api/v1/sessions`, `/api/v1/contacts`, `/api/v1/messages`, `/api/v1/sessions/{id}/messages`, `/api/v1/group-members`, `/api/v1/sns/timeline`, `/api/v1/sns/export/stats`, `/api/v1/push/messages`, and write-operation paths marked with `x-weflowbridge-risk: write-operation`.

Create JSON Schemas for the AI envelope and project manifest using draft 2020-12.

Create the example with only redacted placeholders such as `<redacted:chatroom>`.

- [ ] **Step 4: Run target tests and see pass**

Run: `python -m unittest tests\test_project_contracts.py`

Expected: all tests pass.

- [ ] **Step 5: Commit**

Run: `git add docs/openapi.yaml schemas/ai-consumer-envelope.v2.schema.json schemas/project-manifest.v1.schema.json docs/examples/ai_consumer_envelope.example.json project_manifest.json tests/test_project_contracts.py`

Run: `git commit -m "feat: add machine-readable AI integration contracts"`

### Task 2: Public Boundary and CI Local Scripts

**Files:**
- Create: `tools/test-public-boundary.ps1`
- Create: `tools/test-ci-local.ps1`
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- `tools/test-public-boundary.ps1` exits `0` when tracked files are public-safe and parseable.
- `tools/test-ci-local.ps1` exits `0` after running Python contract tests and public-boundary checks.

- [ ] **Step 1: Write failing tests**

Add tests that assert both tools exist, contain the expected commands, and that the public-boundary tool includes checks for private path patterns, high-confidence secret patterns, and PowerShell parser coverage for `probe-weflow.ps1`, `weflow_heartbeat.ps1`, `weflow_boot_guardian.ps1`, and `enable-autologin.ps1`.

- [ ] **Step 2: Run target tests and see failure**

Run: `python -m unittest tests\test_project_contracts.py`

Expected: fail because the tools do not exist.

- [ ] **Step 3: Add scripts**

Implement `tools/test-public-boundary.ps1` with only read-only checks: `git ls-files`, `git check-ignore`, high-confidence secret regex scan, optional `pdftotext` scan when available, and PowerShell parser checks.

Implement `tools/test-ci-local.ps1` to run `python -m unittest tests\test_project_contracts.py` and then `tools/test-public-boundary.ps1`.

- [ ] **Step 4: Run scripts**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-public-boundary.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1`

Expected: both exit `0`.

- [ ] **Step 5: Commit**

Run: `git add tools/test-public-boundary.ps1 tools/test-ci-local.ps1 tests/test_project_contracts.py`

Run: `git commit -m "test: add public boundary verification scripts"`

### Task 3: Metadata-Only Probe JSON

**Files:**
- Modify: `probe-weflow.ps1`
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- `probe-weflow.ps1 -Json -Mode MetadataOnly -NoMessages` prints JSON with `schema_version`, `weflow_baseline`, `base_url_redacted`, `token_present`, `mode`, `no_messages`, `privacy`, and `endpoint_results`.
- JSON mode never prints raw token, raw talker, message text, raw response bodies, or media paths.

- [ ] **Step 1: Write failing tests**

Add tests that assert `probe-weflow.ps1` declares `-Json`, `-Mode`, and `-NoMessages`, contains `schema_version`, `base_url_redacted`, `message_text_printed`, and does not include `DefaultPassword` or scheduled-task registration logic.

- [ ] **Step 2: Run target tests and see failure**

Run: `python -m unittest tests\test_project_contracts.py`

Expected: fail because `probe-weflow.ps1` has no JSON mode.

- [ ] **Step 3: Implement JSON mode**

Add parameters, shared endpoint result helpers, redacted base URL output, and a metadata-only branch. Keep the existing human-readable behavior when `-Json` is not set.

- [ ] **Step 4: Verify**

Run: `python -m unittest tests\test_project_contracts.py`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-public-boundary.ps1`

Optional when WeFlow is running: `powershell -NoProfile -ExecutionPolicy Bypass -File probe-weflow.ps1 -Json -Mode MetadataOnly -NoMessages`

Expected: required tests pass; optional JSON output contains no raw messages.

- [ ] **Step 5: Commit**

Run: `git add probe-weflow.ps1 tests/test_project_contracts.py`

Run: `git commit -m "feat: add metadata-only probe JSON mode"`

### Task 4: CI and Documentation Links

**Files:**
- Create: `.github/workflows/contract.yml`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/ai_consumer_contract.md`
- Modify: `docs/closeout_audit.md`
- Modify: `project_manifest.json`
- Modify: `tests/test_project_contracts.py`

**Interfaces:**
- Workflow runs Python contract tests and `tools/test-ci-local.ps1` on Windows.
- Docs point readers to OpenAPI/schema files without duplicating their contents.
- `project_manifest.json.integration_readiness.release_tag = "v0.1.0"`.

- [ ] **Step 1: Write failing tests**

Add tests that assert `.github/workflows/contract.yml` exists, uses `windows-latest`, runs `python -m unittest tests/test_project_contracts.py`, and runs `tools/test-ci-local.ps1`. Add tests that README and AGENTS link to `docs/openapi.yaml` and `schemas/ai-consumer-envelope.v2.schema.json`.

- [ ] **Step 2: Run target tests and see failure**

Run: `python -m unittest tests\test_project_contracts.py`

Expected: fail because workflow and links do not exist.

- [ ] **Step 3: Add workflow and docs links**

Create the workflow and add concise links in docs. Update closeout audit from structural closeout to AI Integration 1.0 readiness.

- [ ] **Step 4: Verify**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1`

Run: `git diff --check`

Expected: both pass.

- [ ] **Step 5: Commit**

Run: `git add .github/workflows/contract.yml README.md AGENTS.md docs/ai_consumer_contract.md docs/closeout_audit.md project_manifest.json tests/test_project_contracts.py`

Run: `git commit -m "ci: add contract verification workflow"`

### Task 5: Final Verification, Release, and Index Record

**Files:**
- Modify in index repo: `E:\GitHub总索引\03_推送决策\已推送记录.md` through `tools/Add-PushRecord.ps1` only.

**Interfaces:**
- Branch `codex/weflowbridge-ai-integration-1-0` is pushed.
- `master` is fast-forwarded after verification.
- Tag `v0.1.0` and GitHub release exist.
- Total index logs the public-safe release summary.

- [ ] **Step 1: Run full verification**

Run: `python -m unittest tests\test_project_contracts.py`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-public-boundary.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1`

Run: `git diff --check`

Expected: all pass.

- [ ] **Step 2: Push branch**

Run: `git push -u origin codex/weflowbridge-ai-integration-1-0`

- [ ] **Step 3: Fast-forward master and push**

Run from `E:\Projects\Tools\WeFlowBridge`: `git fetch origin; git merge --ff-only codex/weflowbridge-ai-integration-1-0; git push origin master`

- [ ] **Step 4: Tag and release**

Run: `git tag -a v0.1.0 -m "WeFlowBridge AI Consumer Contract v2 baseline"`

Run: `git push origin v0.1.0`

Run: `gh release create v0.1.0 --repo wlyaaaaa/WeFlowBridge --title "WeFlowBridge v0.1.0 - WeFlow 26.7.3 / AI Consumer Contract v2 baseline" --notes-file <release-notes-file>`

- [ ] **Step 5: Record total index**

Run `E:\GitHub总索引\tools\Add-PushRecord.ps1` with public-safe release summary, then push `E:\GitHub总索引` `main`.
