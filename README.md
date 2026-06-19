# WeFlowBridge

> 给我（主脑）、Cline 以及任何接入的 AI 看的一份说明：**本机的 WeFlow 微信 API 能调什么、有什么用、怎么安全地用。**
>
> 这是一个**纯文档 / 集成说明**仓库，**不含任何代码逻辑、不含任何密钥**。真实 token、数据库密钥等只存在本地 `.env`（已被 `.gitignore` 忽略）。

> **📌 适用版本：WeFlow `26.5.27`（`C:\Program Files\WeFlow\WeFlow.exe`）** · **实测日期：2026-06-20**
> WeFlow 持续更新，接口可能随版本变动。本文端点 = 源码（`app.asar`）抽取 + 本机实测双重确认；换版本后请重跑 `probe-weflow.ps1` 复核，并更新此处版本/日期。

---

## 1. 这是什么

[WeFlow](https://github.com/hicccc77/WeFlow) 是一个**完全本地**运行的微信（4.0+）聊天记录查看 / 分析 / 导出工具。它在本机起一个 HTTP 服务，把"读取并解密本地微信消息"的能力映射成 REST 接口，供外部脚本、自动化、以及 **AI Agent** 调用。

- **服务地址**：`http://127.0.0.1:5031`（仅监听本地回环，不对外网开放）
- **启用方式**：WeFlow 客户端 → 设置 → API 服务 → 启动服务
- **输出格式**：原始 JSON，或 [ChatLab](https://github.com/nichuanfang/chatlab-format) 标准格式
- **状态**：官方标注"早期阶段，接口可能变动"——以本机实测为准（见 `probe-weflow.ps1`）

> ⚠️ 解密所需的数据库密钥 / 图片密钥都由 **WeFlow 内部持有并使用**，**不是 API 入参**。调接口只需要 base URL（+ token）。

---

## 2. 它能用来干嘛（对 AI 而言）

| 场景 | 怎么实现 |
|------|----------|
| **检索某人/某群的聊天记录** | `GET /api/v1/messages?talker=<id>`，支持时间范围、关键词、分页 |
| **让 AI 总结/分析一段对话** | 拉 `chatlab=1` 标准格式 → 直接喂给模型做摘要、情绪、画像 |
| **列出所有会话 / 找某个会话** | `GET /api/v1/sessions?keyword=工作群` |
| **导出联系人** | `GET /api/v1/contacts?keyword=张三` |
| **群成员画像（谁是群主/发言量）** | `GET /api/v1/group-members?talker=<群id>`，含 `isOwner`/`messageCount` 等 |
| **读/分析朋友圈** | `GET /api/v1/sns/timeline`（含点赞、评论、定位）+ `GET /api/v1/sns/export/stats` |
| **拿到图片/语音/视频文件** | 查询时 `media=1` 导出，再用 `/api/v1/media/...` 取文件 |
| **健康检查 / 服务是否在线** | `GET /health` |

一句话：**它把"我的微信历史 + 朋友圈"变成一个 AI 可读的本地数据源**——可以做检索、摘要、年度报告、双人关系分析、群画像、朋友圈分析、媒体提取等。

> 完整端点（含上面没列全的朋友圈/防删等）见 [§4.5 完整端点地图](#45-完整端点地图weflow-26527实测于-2026-06-20)。

---

## 3. 接口参考

所有接口均为 `GET`，base = `http://127.0.0.1:5031`。

### `GET /health` — 健康检查
返回 `{ "status": "ok" }`。用来判断服务是否启动。

### `GET /api/v1/sessions` — 会话列表
| 参数 | 必填 | 说明 |
|------|------|------|
| `keyword` | ❌ | 按会话名 / ID 搜索 |
| `limit` | ❌ | 数量上限，默认 100 |

返回 `sessions[]`（**2026-06-20 实测字段**，与官方文档略有出入）：`username` / `displayName` / `type` / `sessionType`（`private`|`group`）/ `lastTimestamp`（秒级时间戳）/ `unreadCount`。

### `GET /api/v1/contacts` — 联系人列表
| 参数 | 必填 | 说明 |
|------|------|------|
| `keyword` | ❌ | 搜索关键词 |
| `limit` | ❌ | 数量上限，默认 100 |

返回 `contacts[]`（**2026-06-20 实测字段**）：`username` / `displayName` / `nickname` / `type`。

### `GET /api/v1/messages` — 消息（核心接口）
| 参数 | 必填 | 说明 |
|------|------|------|
| `talker` | ✅ | 会话 ID（wxid 或群 ID） |
| `limit` | ❌ | 返回条数，默认 100，范围 1~10000 |
| `offset` | ❌ | 分页偏移，默认 0 |
| `start` / `end` | ❌ | 时间范围，格式 `YYYYMMDD` |
| `keyword` | ❌ | 按消息显示文本过滤 |
| `chatlab` | ❌ | `1` = 输出 ChatLab 格式 |
| `format` | ❌ | `json`（默认）或 `chatlab` |
| `media` | ❌ | `1` = 同时导出媒体并返回路径；`0` = 占位符 |
| `image`/`voice`/`video`/`emoji` | ❌ | `media=1` 时分别控制各类媒体导出（`1/0`） |

媒体默认导出到（**实测**）`%APPDATA%\weflow\cache\api-media`。

> ⚠️ **实测必读**：不传 `start`/`end` 时，默认时间窗很窄，`/messages` 经常返回 `count=0`。要取到历史消息**务必显式给** `start`/`end`（如 `start=20250101&end=20261231`）。

**示例**
```
GET /api/v1/messages?talker=wxid_xxx&limit=50
GET /api/v1/messages?talker=wxid_xxx&chatlab=1
GET /api/v1/messages?talker=wxid_xxx&start=20260101&end=20260205&limit=100
GET /api/v1/messages?talker=wxid_xxx&keyword=项目进度&limit=50
GET /api/v1/messages?talker=wxid_xxx&media=1&image=1&voice=1&video=0&emoji=0
```

### `GET /api/v1/media/{relativePath}` — 取已导出的媒体
例：`/api/v1/media/wxid_xxx/images/image_123.jpg`。需先用 `media=1` 导出才能访问。支持 png/jpg/gif/webp/wav/mp3/mp4。

### ChatLab 消息类型映射
`0` 文本 · `1` 图片 · `2` 语音 · `3` 视频 · `4` 文件 · `5` 表情 · `7` 链接 · `8` 位置 · `20` 红包 · `21` 转账 · `23` 通话 · `80` 系统 · `81` 撤回 · `99` 其他

---

## 4. 给 AI / 主脑 / Cline 的接入说明

**绝不要把 token / 密钥 / wxid 写进代码或仓库**。一律从本地 `.env` 读：

```powershell
# PowerShell：从 .env 读配置后调用
$cfg = @{}; Get-Content "E:\WeFlowBridge\.env" | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object { $k,$v = $_ -split '=',2; $cfg[$k.Trim()] = $v.Trim() }
$base = $cfg['WEFLOW_BASE_URL']
$headers = @{}; if ($cfg['WEFLOW_TOKEN']) { $headers['Authorization'] = "Bearer $($cfg['WEFLOW_TOKEN'])" }

Invoke-RestMethod "$base/health" -Headers $headers
Invoke-RestMethod "$base/api/v1/sessions?limit=5" -Headers $headers
Invoke-RestMethod "$base/api/v1/messages?talker=wxid_xxx&chatlab=1&limit=20" -Headers $headers
```

```python
# Python
import os, requests
base = os.environ["WEFLOW_BASE_URL"]
h = {"Authorization": f"Bearer {os.environ['WEFLOW_TOKEN']}"} if os.environ.get("WEFLOW_TOKEN") else {}
msgs = requests.get(f"{base}/api/v1/messages",
                    params={"talker": "wxid_xxx", "chatlab": 1, "limit": 100}, headers=h).json()
```

> **实测（2026-06-20）**：本机这版 WeFlow 对**数据接口强制鉴权** —— 不带 token 返回 `401`，必须带 `Authorization: Bearer <token>`。`/health` 例外（无需 token）。缺 `talker` 返回 `400`。

---

## 4.5 完整端点地图（WeFlow `26.5.27`，实测于 2026-06-20）

> 端点来源：从 `app.asar` 抽取的路由字面量 + 本机逐个活探。**比 fork 文档多出一整套朋友圈(SNS)、群成员、推送端点。** 所有数据接口都强制 `Bearer` 鉴权。

| 端点 | 方法 | 状态 | 说明 / 关键字段 |
|------|------|------|------|
| `/health`、`/api/v1/health` | GET | ✅ 稳定 | `{"status":"ok"}`，**无需 token** |
| `/api/v1/sessions` | GET | ✅ 稳定 | 会话列表：`username`/`displayName`/`type`/`sessionType`/`lastTimestamp`/`unreadCount` |
| `/api/v1/contacts` | GET | ✅ 稳定 | 联系人：`username`/`displayName`/`nickname`/`type` |
| `/api/v1/messages` | GET | ⚠️ 通但不稳 | 消息；需显式 `start`/`end`，结果时有时无（见下） |
| `/api/v1/media/{path}` | GET | ◐ 未坐实 | 取已导出媒体；受 `/messages` 不稳定拖累没稳定捞到样本 |
| `/api/v1/group-members?talker=<群id>` | GET | ✅ 实测可用 | 群成员：`success`/`chatroomId`/`count`/`fromCache`/`updatedAt`/`members[]`；成员字段含 `wxid`/`displayName`/`nickname`/`remark`/`alias`/`groupNickname`/`avatarUrl`/`isOwner`/`isFriend`/`messageCount` |
| `/api/v1/sns/timeline?limit=` | GET | ✅ 实测可用 | 朋友圈时间线：`{success,count,timeline[]}`；条目字段 `tid`/`id`/`username`/`nickname`/`createTime`/`contentDesc`/`type`/`media`/`likes`/`comments`/`rawXml`/`location` |
| `/api/v1/sns/post/{id}` | GET | 需 id（空 id→405） | 单条朋友圈详情 |
| `/api/v1/sns/usernames` | GET | ✅ 实测可用 | `{success,usernames[]}` 有朋友圈的用户名列表 |
| `/api/v1/sns/export` | GET | 未测 | 朋友圈导出 |
| `/api/v1/sns/export/stats` | GET | ✅ 实测可用 | `{success,data:{totalPosts,totalFriends,myPosts}}` |
| `/api/v1/sns/media/proxy` | GET | 未测（需参数） | 朋友圈媒体代理 |
| `/api/v1/sns/block-delete/status` | GET | ✅ 实测可用 | `{success,installed:bool}` 防朋友圈删除钩子状态 |
| `/api/v1/sns/block-delete/install` | **POST** | 写操作（GET→405） | 安装防删钩子 |
| `/api/v1/sns/block-delete/uninstall` | **POST** | 写操作 | 卸载防删钩子 |
| `/api/v1/push/messages` | ? | ⚠️ 403 未坐实 | 实时消息推送；GET/POST 均 403，疑似 SSE 流需特定握手 |

> 注：`/version`、`/info`、`/api/book`、`/api/v3`、`/api/v4` 这些字符串虽在包内出现，但**不是本服务的 HTTP 路由**（实测 404），请勿调用。

> **⚠️ 已知问题（`/messages` 不稳定）**：WeFlow 是"实时读库、无中间解密库"的架构，消息索引疑似惰性/有竞态——相同调用可能这次有数据、下次为 0（实测同一会话在 50 条 / 0 条之间跳）。**建议**：① 务必显式给 `start`/`end`；② 返回 0 或失败时**重试几次**；③ 批量分析前先用 `probe-weflow.ps1` 确认当前能否取到消息；④ 优先依赖 `sessions`/`contacts`/`group-members`/`sns/*` 这些实测稳定的接口。

**典型 Agent 工作流**：`/api/v1/sessions` 找会话 →（群聊可 `/api/v1/group-members` 拿成员画像）→ `/api/v1/messages?talker=...&chatlab=1` 拉标准化记录 → 交给模型做摘要 / 分析 / 报告；朋友圈分析走 `/api/v1/sns/timeline` + `/sns/export/stats`。

---

## 5. 安全模型与红线 ⚠️

WeFlow API 的安全完全依赖**两点**，缺一不可：

1. **只绑定 `127.0.0.1`**——绝不要用端口转发 / 反代 / `0.0.0.0` 把它暴露到局域网或公网。一旦暴露，等于把全部微信记录裸奔。
2. **CORS 开放 + 鉴权弱**——官方文档明确"支持 CORS，可从浏览器前端直接调用"，且示例无鉴权。这意味着**你在浏览器里打开的任意网页，理论上都可能 fetch `127.0.0.1:5031` 来读你的微信数据**。务必：
   - 在 WeFlow 里**开启 token 鉴权**（如果版本支持），别裸跑；
   - 不用时**关掉 API 服务**；
   - 别在浏览器开着 API 的同时乱点不明网站。

**密钥红线（本仓库为何坚持私有 + gitignore）**：
- `WEFLOW_DB_KEY`（SQLCipher 库密钥）解密你**全部**聊天历史，且**不可轮换**——进过任何 git 历史 = 永久泄密。
- `WEFLOW_TOKEN` 可在 WeFlow 设置里**重新生成**——本仓库建好后建议立刻轮换一次（它曾出现在对话/剪贴板里）。
- 你有过把 TG token 误推进公开仓库的前例，所以这里**默认私有、密钥只进 `.env`**，README 里全用 `wxid_xxx` 占位。

---

## 6. 快速自检

```powershell
pwsh E:\WeFlowBridge\probe-weflow.ps1
```
脚本会从 `.env` 读 base/token，依次打 `/health`、`/sessions`、`/contacts`，告诉你服务是否在线、鉴权方式、能不能取到数据。

---

## 7. 来源与致谢

- WeFlow 本体：<https://github.com/hicccc77/WeFlow>
- 本文 API 端点依据其 `docs/HTTP-API.md`（经 fork `RuoCJ/WeFlowBack` 取回，官方主仓库未公开该文件）
- ChatLab 格式：<https://github.com/nichuanfang/chatlab-format>

> 请负责任地使用，仅处理你本人有权访问的数据，遵守相关法律法规。
