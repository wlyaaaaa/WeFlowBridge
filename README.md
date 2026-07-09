# WeFlowBridge

> Local-first WeChat API bridge for AI agents, built on WeFlow 26.7.3.

WeFlowBridge documents, verifies, and wraps WeFlow's local HTTP API so AI agents can safely read WeChat sessions, messages, contacts, group members, and Moments metadata without leaking tokens, raw transcripts, database files, or media paths.

It is not a WeChat data dump and it is not a hosted service. It is a public, privacy-focused integration layer for people who already run [WeFlow](https://github.com/hicccc77/WeFlow) locally and want AI tools, scripts, or ChatLab-style consumers to talk to it through a stable contract.

**Verified baseline:** WeFlow 26.7.3 / ProductVersion `26.7.3.0`, verified on 2026-07-09. WeFlow is still evolving, so rerun `probe-weflow.ps1` after every WeFlow upgrade.

## Why this exists

WeFlow can expose local WeChat history through an HTTP API, but AI integration needs more than a list of endpoints. Agents need to know which endpoint is stable, which call leaks too much, how to handle retry-prone message reads, how to preserve sync cursors, and what must never be committed to a public repository.

WeFlowBridge turns that local API surface into a documented and testable AI consumer boundary:

- safe defaults for AI agents reading local WeChat data
- OpenAPI docs for endpoint shape and risk markers
- JSON Schema files for metadata-first AI envelopes
- probe scripts for checking the live WeFlow instance
- privacy guardrails that keep raw messages, tokens, databases, screenshots, exports, and media paths out of Git
- contract tests and GitHub Actions so the public integration contract stays closed

## What you get

| Need | File or command |
| --- | --- |
| AI-facing endpoint map | [docs/openapi.yaml](docs/openapi.yaml) |
| AI Consumer Contract v2 | [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md) |
| Metadata envelope schema | [schemas/ai-consumer-envelope.v2.schema.json](schemas/ai-consumer-envelope.v2.schema.json) |
| Project manifest schema | [schemas/project-manifest.v1.schema.json](schemas/project-manifest.v1.schema.json) |
| Example safe envelope | [docs/examples/ai_consumer_envelope.example.json](docs/examples/ai_consumer_envelope.example.json) |
| Public privacy boundary | [docs/privacy_boundary.md](docs/privacy_boundary.md) |
| Closeout and verification audit | [docs/closeout_audit.md](docs/closeout_audit.md) |
| Live local probe | `powershell -ExecutionPolicy Bypass -File probe-weflow.ps1` |
| Contract tests | `python -m unittest tests\test_project_contracts.py` |
| Local CI and privacy scan | `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1` |

The machine-readable project boundary is [project_manifest.json](project_manifest.json). It records the current WeFlow baseline, public repository role, safe verification commands, and AI integration readiness status.

## What this repository never stores

This repository is public. It is designed to be useful without containing private WeChat material.

- no `.env` values
- no `WEFLOW_TOKEN` or database keys
- no raw messages or ChatLab exports
- no WeChat database files
- no screenshots
- no media files, media payloads, or local media paths
- no complete local machine logs

AI consumers should produce metadata-first envelopes by default. Message content is opt-in for local runtime use, and durable outputs should prefer counts, timestamps, sync cursors, reply metadata, and non-path `media_manifest` records.

## Quickstart

1. Install and start WeFlow locally.
2. In WeFlow, enable the API service.
3. Create a local `.env` from `.env.example` and fill in your local base URL and token.
4. Run the safe metadata probe:

```powershell
powershell -ExecutionPolicy Bypass -File probe-weflow.ps1 -Json -Mode MetadataOnly -NoMessages
```

5. Run the public contract tests:

```powershell
python -m unittest tests\test_project_contracts.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1
```

The probe reads local configuration, checks `/health`, sessions, contacts, group members, SNS stats, and message endpoint shape, then prints redacted JSON. `-Mode MetadataOnly` intentionally avoids reading message bodies.

## 中文说明

WeFlowBridge 是一个面向 AI Agent 的本地微信数据 API 桥接层。它不保存微信原始数据，也不替代 WeFlow 本体；它负责把 WeFlow 26.7.3 的本地 HTTP API 整理成公开可读、可测试、可脱敏、可给 AI 集成的契约。

最推荐的实际 AI 调用层是 `weflow-toolkit v0.2+`。调用时应遵守 [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md)：先判断当前 WeFlow 库，最新消息：不带 start/end，历史/批量读取优先 ChatLab Pull，输出 `current_library`、`target_conversation`、`talker`、`time_window`、`retry_count`、`message_count`、`lastTimestamp_matches_newest`、`request_method`、`endpoint_family`、`sync_watermark` 和 `media_manifest` 等字段。

## Core API Shape

Base URL is usually `http://127.0.0.1:5031`. `/health` does not require a token. Data endpoints require a token through `Authorization: Bearer <token>`, `?access_token=<token>`, or request body `access_token`. Prefer the bearer header except for browser `EventSource`, where SSE requires the query string form.

| Purpose | Endpoint |
| --- | --- |
| Service health | `GET /health` |
| Sessions | `GET/POST /api/v1/sessions` |
| ChatLab session index | `GET /api/v1/sessions?format=chatlab` |
| Contacts | `GET/POST /api/v1/contacts` |
| Latest messages | `GET/POST /api/v1/messages?talker=<conversation-id>&limit=100` |
| ChatLab Pull history | `GET /api/v1/sessions/{id}/messages?since=<unix>&end=<unix>&limit=5000&offset=0` |
| Group members | `GET/POST /api/v1/group-members?talker=<conversation-id>` |
| Moments timeline | `GET /api/v1/sns/timeline?limit=<n>` |
| Moments stats | `GET /api/v1/sns/export/stats` |
| Push stream | `GET /api/v1/push/messages?access_token=<token>` |

For AI history reads, ChatLab Pull is the preferred path:

```text
GET /api/v1/sessions?format=chatlab
GET /api/v1/sessions/{id}/messages?since=<unix_seconds>&end=<unix_seconds>&limit=5000&offset=0
```

`/api/v1/sessions/{id}/messages` returns `chatlab`, `meta`, `members`, `messages`, and `sync`. Preserve `sync.hasMore`, `sync.nextSince`, `sync.nextOffset`, and `sync.watermark`. For reply reconstruction, preserve `replyToMessageId` and `quote`. For media, durable AI output should keep only non-path `media_manifest` metadata.

## Endpoint Notes

- `/api/v1/messages` is useful but can be retry-prone because WeFlow reads the live local database. For latest messages, do not use `start/end`; request `limit=100`, treat index `0` as newest, and compare it with `sessions.lastTimestamp`.
- Historical or bulk reads should prefer ChatLab Pull through `/api/v1/sessions/{id}/messages`.
- Most read endpoints accept both `GET` query parameters and `POST` JSON bodies. Use `GET` for simple calls and `POST` when the request shape is easier to express as JSON.
- Write operations such as SNS export, SNS post delete, and block-delete install/uninstall are documented but marked as not AI-callable in [docs/openapi.yaml](docs/openapi.yaml).
- The push stream is documented for completeness, but it is not a default AI envelope endpoint because it is a live raw stream.

## PowerShell Example

```powershell
$cfg = @{}
Get-Content ".env" |
  Where-Object { $_ -match '^\s*[^#].*=' } |
  ForEach-Object {
    $k, $v = $_ -split '=', 2
    $cfg[$k.Trim()] = $v.Trim()
  }

$base = $cfg['WEFLOW_BASE_URL']
$headers = @{ Authorization = "Bearer $($cfg['WEFLOW_TOKEN'])" }

Invoke-RestMethod "$base/health"
Invoke-RestMethod "$base/api/v1/sessions?limit=5" -Headers $headers
Invoke-RestMethod "$base/api/v1/messages?talker=<conversation-id>&limit=100" -Headers $headers
Invoke-RestMethod "$base/api/v1/sessions/<conversation-id>/messages?since=1760000000&end=1760003600&limit=5000&offset=0" -Headers $headers
```

## Python Example

```python
import os
import requests

base = os.environ["WEFLOW_BASE_URL"]
headers = {"Authorization": f"Bearer {os.environ['WEFLOW_TOKEN']}"}

latest = requests.get(
    f"{base}/api/v1/messages",
    params={"talker": "<conversation-id>", "limit": 100},
    headers=headers,
).json()

history = requests.get(
    f"{base}/api/v1/sessions/<conversation-id>/messages",
    params={"since": 1760000000, "end": 1760003600, "limit": 5000, "offset": 0},
    headers=headers,
).json()
```

## Safety Model

WeFlowBridge assumes a local-only WeFlow deployment:

1. Keep WeFlow bound to `127.0.0.1`.
2. Do not expose the WeFlow port through a reverse proxy, port forward, tunnel, or `0.0.0.0` listener.
3. Treat `WEFLOW_TOKEN` as a read key for local WeChat data.
4. Treat database keys as non-rotatable secrets.
5. Keep `.env` local and ignored.
6. Submit public changes through the local CI and public-boundary scanner.

The public scanner checks tracked paths, ignored private-output paths, high-confidence secret patterns, PowerShell parser coverage, and known raw export/media naming patterns.

## Repository Status

- AI Integration 1.0 status: `ready_for_normal_maintenance`
- Release tag: `v0.1.0`
- Verified WeFlow baseline: `26.7.3`
- Contract version: AI Consumer Contract v2
- CI: `.github/workflows/contract.yml`

Reopen the integration audit when WeFlow changes API behavior, message ordering semantics drift, privacy guardrails fail, or a downstream AI consumer needs a new envelope field.

## Credits

- WeFlow: <https://github.com/hicccc77/WeFlow>
- ChatLab format: <https://github.com/nichuanfang/chatlab-format>

Use this project only for data you are allowed to access, and keep private conversation data private.
