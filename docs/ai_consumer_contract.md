# AI Consumer Contract

This document defines how AI consumers should use `E:\WeFlowBridge` as a WeChat data source adapter.

## Project Role

`E:\WeFlowBridge` is the provider-facing adapter for local WeFlow data access. It owns public-safe endpoint notes, health checks, watchdog scripts, and the contract for AI consumers.

It does not own relationship analysis, career analysis, PersonalOS memory, raw message archives, or long-term semantic indexes. Those belong to downstream projects that call this adapter through approved skills.

## Consumer Layers

| Consumer | Allowed role | Not allowed |
| --- | --- | --- |
| `.agents` / `weflow-toolkit` | Call the local API, judge active library, normalize metadata, enforce privacy rules | Store raw chat history as durable project data |
| `PersonalOS` | Register WeChat history as an available data source | Copy full chat exports or maintain duplicate WeFlow state |
| `CareerCapital` | Query work-related conversations when a task needs evidence | Own family, romance, or unrelated social facts |
| `SocialCapital` | Query relationship, family, romance, and friend context when needed | Own career negotiation or salary facts |
| `LifeCases` | Pull excerpts as evidence for a specific cross-domain case | Become a permanent WeChat archive |

## Required Output Envelope

Any AI consumer that reads WeFlow messages must report or internally preserve these fields:

| Field | Meaning |
| --- | --- |
| `current_library` | Active WeFlow account database judgment: `root`, `亦泊`, or `unknown` |
| `library_evidence` | One or two evidence strings used to judge the active library |
| `target_account` | Account requested by the user, if any |
| `target_conversation` | Human-readable target group or contact name |
| `talker` | WeFlow conversation ID used for `/api/v1/messages` |
| `time_window` | `latest`, or explicit `start/end` dates for historical reads |
| `retry_count` | Number of retries after empty or suspicious responses |
| `message_count` | Number of messages returned in the final batch |
| `lastTimestamp_matches_newest` | Whether `sessions.lastTimestamp` equals `messages[0].createTime` for latest reads |
| `content_scope` | Whether output contains metadata only, excerpts, or full text |

## Retrieval Rules

Latest messages:

1. Use `GET /api/v1/messages?talker=<talker>&limit=100`.
2. Do not pass `start/end`.
3. Treat returned messages as `createTime` descending; newest is index `0`.
4. Compare `sessions.lastTimestamp` with `messages[0].createTime`.
5. If they do not match, say the latest batch may be incomplete and retry or change parameters.

Historical reads:

1. Use explicit `start=<YYYYMMDD>&end=<YYYYMMDD>`.
2. Use a bounded window that fits the user request.
3. Do not infer "no messages" from a single empty response; retry first.

Time handling:

1. Treat Unix timestamps as UTC epoch seconds.
2. Convert Chinese-context output to Beijing time with `UTC+8`.
3. Do not use system local timezone as truth.

## Account Judgment

Before reading a target conversation, consumers must judge the active WeFlow database:

1. `GET /api/v1/sessions?limit=80`
2. `GET /api/v1/contacts?keyword=root&limit=20`
3. `GET /api/v1/contacts?keyword=亦泊&limit=20`
4. If the target is a group, also query `GET /api/v1/sessions?keyword=<keyword>&limit=10000`

If the requested account and active library do not match, do not present current-library results as if they came from the requested account.

## Failure Semantics

- Missing target conversation means "not found in the current WeFlow library", not "the conversation does not exist".
- Empty message results mean "empty or unstable response after N retries", not "no messages", unless the active library and time window are verified.
- A forwarded XML source is not proof that the target group is readable in the active library.
- A successful metadata probe is not consent to publish raw messages.

## Stable Integration Decision

Do not create a separate E-drive project just to manage WeFlow access. The current ownership is:

- `E:\WeFlowBridge`: adapter, watchdog, public-safe docs, consumer contract.
- `E:\.agents\plugins\weflow-toolkit`: AI calling skill and helper scripts.
- Downstream projects: task-specific analysis and decisions.

Create a new private project only if there is a future need for a durable WeChat archive, vector index, relationship knowledge base, or large-scale export pipeline.
