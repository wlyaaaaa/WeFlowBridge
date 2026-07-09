# WeFlowBridge AI Integration 1.0 Design

## Goal

Make WeFlowBridge complete as a public-safe, AI-ready adapter by adding machine-readable contracts, local/CI verification, privacy scanning, a metadata-only probe mode, and a versioned release point.

## Definition of Complete

WeFlowBridge is complete for normal maintenance when all of these are true:

- Public docs remain the human entrypoint for WeFlow `26.7.3` / ProductVersion `26.7.3.0`.
- `docs/openapi.yaml` describes the public-safe HTTP API view that AI tooling may inspect.
- `schemas/ai-consumer-envelope.v2.schema.json` validates the AI Consumer Contract v2 output envelope.
- `schemas/project-manifest.v1.schema.json` validates `project_manifest.json`.
- `project_manifest.json` points to every machine contract and records `integration_readiness`.
- `probe-weflow.ps1` can emit metadata-only JSON without printing raw talkers, message text, media paths, or token values.
- Local and CI tests verify contract files, PowerShell parseability, privacy boundaries, and GitHub workflow presence.
- The repository has a `v0.1.0` tag and GitHub release for the AI Consumer Contract v2 baseline.

## Non-Goals

- Do not create a SDK, MCP server, mock server, vector index, long-term transcript archive, or WeChat analytics product in this repository.
- Do not store raw messages, ChatLab exports, screenshots, database files, media payloads, local media paths, token values, or real `wxid_...` / `...@chatroom` identifiers.
- Do not run GUI launchers, scheduled-task registration, Windows autologin, or registry writes in CI.
- Do not make the OpenAPI file a complete upstream WeFlow replacement; it is the stable AI-facing view for this adapter.

## Architecture

The implementation separates human guidance, machine contracts, and runtime probing:

- `README.md`, `AGENTS.md`, and `docs/ai_consumer_contract.md` stay concise human-facing guidance.
- `docs/openapi.yaml` owns HTTP method, path, auth, parameter, and response-shape documentation.
- `schemas/*.schema.json` own machine validation for AI envelopes and project metadata.
- `project_manifest.json` indexes the contract files instead of duplicating their contents.
- `probe-weflow.ps1` keeps the existing human-readable probe and adds an opt-in JSON mode for automated smoke checks.
- `tools/test-public-boundary.ps1` and `.github/workflows/contract.yml` provide repeatable public-safety verification without live WeFlow access.

## Testing Strategy

Tests are deliberately split between static public-repository checks and optional local runtime checks:

- `python -m unittest tests/test_project_contracts.py` checks manifests, schemas, OpenAPI coverage, docs links, and workflow references.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-public-boundary.ps1` checks tracked files, ignored private paths, PowerShell parseability, and high-confidence secret patterns.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-ci-local.ps1` runs the same checks used by GitHub Actions.
- `powershell -NoProfile -ExecutionPolicy Bypass -File probe-weflow.ps1 -Json -Mode MetadataOnly -NoMessages` is optional and local-only because it talks to the live WeFlow service.

## Release Strategy

After tests and public-boundary scans pass, push `codex/weflowbridge-ai-integration-1-0`, fast-forward `master`, tag `v0.1.0`, create a GitHub release, and record the public-safe summary in `E:\GitHub总索引` with `tools/Add-PushRecord.ps1`.
