# WeFlowBridge

> 给我（主脑）、Cline 以及任何接入的 AI 看的一份说明：**本机的 WeFlow 微信 API 能调什么、有什么用、怎么安全地用。**
>
> 这是一个**纯文档 / 集成说明**仓库，**不含任何代码逻辑、不含任何密钥**。真实 token、数据库密钥等只存在本地 `.env`（已被 `.gitignore` 忽略）。

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
| **导出联系人 / 群成员** | `GET /api/v1/contacts?keyword=张三` |
| **拿到图片/语音/视频文件** | 查询时 `media=1` 导出，再用 `/api/v1/media/...` 取文件 |
| **健康检查 / 服务是否在线** | `GET /health` |

一句话：**它把"我的微信历史"变成一个 AI 可读的本地数据源**——可以做检索、摘要、年度报告、双人关系分析、媒体提取等。

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

返回 `sessions[]`：`username` / `displayName` / `lastMessage` / `lastTime` / `unreadCount`。

### `GET /api/v1/contacts` — 联系人列表
| 参数 | 必填 | 说明 |
|------|------|------|
| `keyword` | ❌ | 搜索关键词 |
| `limit` | ❌ | 数量上限，默认 100 |

返回 `contacts[]`：`userName` / `alias` / `nickName` / `remark`。

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

媒体默认导出到 `%USERPROFILE%\Documents\WeFlow\api-media`。

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

> 注：官方文档示例**未带鉴权头**（仅靠绑定 127.0.0.1）。若你这个 WeFlow 版本开了 token，按上面的 `Authorization: Bearer` 传；实测以 `probe-weflow.ps1` 为准。

**典型 Agent 工作流**：`/api/v1/sessions` 找到目标会话 → `/api/v1/messages?talker=...&chatlab=1` 拉标准化记录 → 交给模型做摘要 / 分析 / 报告。

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
