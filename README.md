# 微信聊天记录 AI 本地桥（WeChat History AI Bridge）

> 想让 AI 安全读取、检索和总结本地微信聊天记录？
> 本项目基于 WeFlow 26.7.3，把本地微信 HTTP API 整理成可验证、可脱敏、可集成的 AI 消费契约。

English: Local-first WeChat chat history bridge for AI agents, powered by WeFlow.

很多人真正想找的是：

- 微信聊天记录怎么导出
- 微信聊天记录怎么给 AI 分析
- 微信群聊天记录怎么总结
- 微信聊天记录有没有本地 API
- 怎么不上传云端也能让 AI 读微信记录

WeFlow 负责本地读取微信数据；WeFlowBridge 负责把它整理成 AI 友好的安全接口、OpenAPI、Schema、自检脚本和隐私边界。换句话说，本项目不替代 WeFlow，也不保存你的微信数据，它只把本地能力整理成 AI Agent 更容易、也更安全使用的桥接层。

**适用基线：** WeFlow 26.7.3 / ProductVersion `26.7.3.0`，实测于 2026-07-09。WeFlow 持续更新，换版本后请重新运行 `probe-weflow.ps1`。

## 这个项目解决什么

如果你只想“导出微信聊天记录”，WeFlow 本体已经很接近答案。这个仓库解决的是下一步：**怎么把本地微信记录安全交给 AI 使用**。

典型场景：

- 让 AI 总结某个微信群最近聊了什么
- 检索某个人、某个群、某个时间段的历史聊天记录
- 把微信聊天记录接入 Codex、Cline、个人 Agent 或 RAG
- 分析群成员、朋友圈、消息时间线
- 在不上传云端、不泄露 token、不提交原始聊天记录的前提下使用 AI

本仓库提供的是中间层：

- 面向 AI 的接口说明和风险标记
- OpenAPI 文档
- JSON Schema 和 metadata-first envelope
- 本地探活 / 自检脚本
- 公开仓库隐私边界
- contract tests 和 GitHub Actions

## 你会得到什么

| 需求 | 文件或命令 |
| --- | --- |
| AI 可读的端点地图 | [docs/openapi.yaml](docs/openapi.yaml) |
| AI Consumer Contract v2 | [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md) |
| 脱敏 metadata envelope schema | [schemas/ai-consumer-envelope.v2.schema.json](schemas/ai-consumer-envelope.v2.schema.json) |
| 项目 manifest schema | [schemas/project-manifest.v1.schema.json](schemas/project-manifest.v1.schema.json) |
| 安全 envelope 示例 | [docs/examples/ai_consumer_envelope.example.json](docs/examples/ai_consumer_envelope.example.json) |
| 公开仓库隐私边界 | [docs/privacy_boundary.md](docs/privacy_boundary.md) |
| 收尾与验证审计 | [docs/closeout_audit.md](docs/closeout_audit.md) |
| 本地 WeFlow 探活 | `powershell -ExecutionPolicy Bypass -File probe-weflow.ps1` |
| 契约测试 | `python -m unittest tests\test_project_contracts.py` |
| 本地 CI + 公开边界扫描 | `powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1` |

机器可读项目边界见 [project_manifest.json](project_manifest.json)，它记录当前 WeFlow 基线、公开仓库角色、安全验证命令和 AI 集成就绪状态。

## 这个仓库绝不保存什么

这是公开仓库，所以默认把每个提交都当作公开材料处理。

- 不保存 `.env`
- 不保存 `WEFLOW_TOKEN` 或数据库密钥
- 不保存原始消息、完整 transcript 或 ChatLab exports
- 不保存微信数据库文件
- 不保存聊天截图、联系人截图或二维码
- 不保存媒体文件、媒体 payload 或本机媒体路径
- 不保存完整本机日志

AI 输出默认应走 metadata-first：优先保存数量、时间窗口、重试次数、sync 游标、回复关系和 non-path `media_manifest`；消息正文只在本地运行时按需读取，不应持久化进这个公开仓库。

## 快速开始

1. 安装并启动 WeFlow。
2. 在 WeFlow 设置里开启 API 服务。
3. 复制 `.env.example` 为本地 `.env`，填入本机 base URL 和 token。
4. 运行 metadata-only 探测：

```powershell
powershell -ExecutionPolicy Bypass -File probe-weflow.ps1 -Json -Mode MetadataOnly -NoMessages
```

5. 运行公开契约测试：

```powershell
python -m unittest tests\test_project_contracts.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-ci-local.ps1
```

`-Mode MetadataOnly` 会检查接口形状、计数、sync 信息和脱敏状态，刻意不读取消息正文。

## 推荐给 AI Agent 的读取方式

实际 AI 调用层推荐使用 `weflow-toolkit v0.2+`。调用时遵守 [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md)：

- 先判断当前 WeFlow 连接的是哪个微信数据库
- 最新消息：不带 start/end，直接 `limit=100`
- 历史/批量读取优先 ChatLab Pull
- 输出 `current_library`、`target_conversation`、`talker`、`time_window`、`retry_count`、`message_count`、`lastTimestamp_matches_newest`、`request_method`、`endpoint_family`、`sync_watermark` 和 `media_manifest`
- 不把 token、raw messages、raw media paths 或完整导出写入公开产物

## 核心接口

base URL 通常是 `http://127.0.0.1:5031`。`/health` 不需要 token，数据接口需要 token。推荐用 `Authorization: Bearer <token>`；浏览器 `EventSource` 连接 SSE 时只能用 `?access_token=<token>`。

| 目的 | 端点 |
| --- | --- |
| 服务探活 | `GET /health` |
| 会话列表 | `GET/POST /api/v1/sessions` |
| ChatLab 会话索引 | `GET /api/v1/sessions?format=chatlab` |
| 联系人 | `GET/POST /api/v1/contacts` |
| 最新消息 | `GET/POST /api/v1/messages?talker=<conversation-id>&limit=100` |
| ChatLab Pull 历史读取 | `GET /api/v1/sessions/{id}/messages?since=<unix>&end=<unix>&limit=5000&offset=0` |
| 群成员 | `GET/POST /api/v1/group-members?talker=<conversation-id>` |
| 朋友圈时间线 | `GET /api/v1/sns/timeline?limit=<n>` |
| 朋友圈统计 | `GET /api/v1/sns/export/stats` |
| 实时推送流 | `GET /api/v1/push/messages?access_token=<token>` |

历史读取优先用 ChatLab Pull：

```text
GET /api/v1/sessions?format=chatlab
GET /api/v1/sessions/{id}/messages?since=<unix_seconds>&end=<unix_seconds>&limit=5000&offset=0
```

`/api/v1/sessions/{id}/messages` 返回 `chatlab`、`meta`、`members`、`messages` 和 `sync`。AI 消费者应保留 `sync.hasMore`、`sync.nextSince`、`sync.nextOffset` 和 `sync.watermark`；回复链保留 `replyToMessageId` 和 `quote`；媒体只持久化 non-path `media_manifest`。

## 调用注意

- `/api/v1/messages` 可用但不够稳定，因为 WeFlow 是实时读本地库。取最新消息时不要用 `start/end`，直接请求 `limit=100`，把索引 `0` 当作最新，并与 `sessions.lastTimestamp` 自检。
- 历史或批量读取优先用 `/api/v1/sessions/{id}/messages`。
- 多数只读接口同时支持 `GET` query 和 `POST` JSON body。简单调用用 `GET`，复杂参数可用 `POST`。
- SNS 导出、朋友圈删除、防删钩子安装/卸载等写操作只做文档记录，OpenAPI 中标记为不允许 AI 默认调用。
- push stream 是实时原始流，不作为默认 AI envelope endpoint。

## PowerShell 示例

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

## Python 示例

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

## 安全模型

本项目默认假设 WeFlow 只在本机运行：

1. 保持 WeFlow 绑定 `127.0.0.1`。
2. 不要通过反代、端口转发、隧道或 `0.0.0.0` 把 WeFlow API 暴露出去。
3. 把 `WEFLOW_TOKEN` 当作可读取本地微信数据的敏感凭据。
4. 把数据库密钥当作不可轮换密钥。
5. `.env` 只留在本地并保持 ignored。
6. 提交前运行本地 CI 和公开边界扫描。

## 项目状态

- 工程兼容名：`WeFlowBridge`
- 公开展示名：`微信聊天记录 AI 本地桥（WeChat History AI Bridge）`
- AI Integration 1.0：`ready_for_normal_maintenance`
- Release tag：`v0.1.0`
- WeFlow 基线：`26.7.3`
- Contract version：AI Consumer Contract v2
- CI：`.github/workflows/contract.yml`

当 WeFlow API 行为变化、消息排序语义漂移、隐私边界失败，或下游 AI 消费者需要新 envelope 字段时，再重新打开集成审计。

## 致谢

- WeFlow: <https://github.com/hicccc77/WeFlow>
- ChatLab format: <https://github.com/nichuanfang/chatlab-format>

请只处理你有权访问的数据，并把私人聊天记录留在本地。
