# AGENTS.md — WeFlow API 给 AI Agent 的速查

> 一页纸够你上手；要细节看 [README.md](README.md)（尤其 §4.5 完整端点地图）。
> **基线：WeFlow `26.5.27`，实测 2026-06-20。** 换版本先跑 `probe-weflow.ps1` 复核。
> 机器可读边界看 [project_manifest.json](project_manifest.json)。AI 消费契约看 [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md)，公开仓库隐私边界看 [docs/privacy_boundary.md](docs/privacy_boundary.md)。

## 它是什么
本机 `http://127.0.0.1:5031` 上的 WeFlow HTTP API —— 把**本地微信（4.0+）的聊天记录、联系人、群成员、朋友圈**映射成 REST 接口。只监听回环，外网不可达。解密由 WeFlow 内部完成，**密钥不是接口入参**。

本仓库是 WeFlow 数据源适配器项目，负责公开安全文档、自检、看门狗和 AI 消费契约；它不是原始微信数据仓库，也不是 PersonalOS / CareerCapital / SocialCapital / LifeCases 的长期事实库。

## 鉴权（必读）
除 `/health` 外所有接口都要 token，无 token → `401`。token 三种写法都行：
- 请求头 `Authorization: Bearer <token>`（推荐）
- query `?access_token=<token>`（**SSE 推送只能用这种**，浏览器 EventSource 不能设头）
- body 字段 `access_token`

**token 从本地 `.env` 读，禁止写进代码 / 仓库 / 日志。**

## 优先用这些（实测稳定）
| 目的 | 调用 |
|------|------|
| 服务在线？ | `GET /health`（无需 token） |
| 会话列表 | `GET /api/v1/sessions?keyword=&limit=` |
| 联系人 | `GET /api/v1/contacts?keyword=&limit=` |
| 群成员画像 | `GET /api/v1/group-members?talker=<群id>`（含 `isOwner`/`messageCount`） |
| 朋友圈时间线 / 统计 | `GET /api/v1/sns/timeline?limit=` · `GET /api/v1/sns/export/stats` |

## 谨慎用（实测不稳定）
- `GET /api/v1/messages?talker=<id>` — 取消息。**最新消息**优先不带 `start/end`，直接 `limit=100`，返回数组按 `createTime` 降序理解，最新在索引 `0`；再用会话 `lastTimestamp` 与第一条消息 `createTime` 自检。**历史区间/批量回溯**才显式给 `start`/`end`（`YYYYMMDD`）。实时读库有竞态，返回 0 时先重试几次 / 换会话，不要直接结论为无消息。要标准化格式加 `&chatlab=1`，要媒体加 `&media=1`。

## 写操作 / 流（知道即可，别误调）
- `POST /api/v1/sns/export`（导出）、`DELETE /api/v1/sns/post/{id}`（删朋友圈）、`POST /api/v1/sns/block-delete/{install,uninstall}`（防删钩子）。
- `GET /api/v1/push/messages?access_token=<token>` — SSE 实时推送（事件 `message.new`/`message.revoke`）。需在 WeFlow 设置开「主动推送」开关，否则 `403 {"error":"Message push is disabled"}`。

## 30 秒 quickstart（PowerShell）
```powershell
$cfg=@{}; Get-Content "E:\WeFlowBridge\.env" | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object { $k,$v=$_ -split '=',2; $cfg[$k.Trim()]=$v.Trim() }
$base=$cfg['WEFLOW_BASE_URL']; $H=@{ Authorization="Bearer $($cfg['WEFLOW_TOKEN'])" }
Invoke-RestMethod "$base/health"
Invoke-RestMethod "$base/api/v1/sessions?limit=5" -Headers $H
# 最新消息：不带 start/end
Invoke-RestMethod "$base/api/v1/messages?talker=<id>&limit=100" -Headers $H
# 历史区间：显式 start/end
Invoke-RestMethod "$base/api/v1/messages?talker=<id>&start=20250101&end=20261231&chatlab=1&limit=50" -Headers $H
```

## curl
```bash
curl -H "Authorization: Bearer $WEFLOW_TOKEN" "http://127.0.0.1:5031/api/v1/sessions?limit=5"
```

## 典型流程
`sessions` 定位会话 → 判断当前库 →（群聊先 `group-members` 拿成员画像）→ 最新消息用无日期 `messages?limit=100` 并做 `lastTimestamp` 自检，历史区间才加 `start/end` → 按 [docs/ai_consumer_contract.md](docs/ai_consumer_contract.md) 输出消费字段；朋友圈走 `sns/timeline` + `sns/export/stats`。

默认不要输出或保存完整原文。公开提交前按 [docs/privacy_boundary.md](docs/privacy_boundary.md) 检查，禁止提交 `.env`、token、raw messages、screenshots、database、exports 或媒体。

## 自检
`powershell -ExecutionPolicy Bypass -File E:\WeFlowBridge\probe-weflow.ps1`

文档/边界契约测试：
`python -m unittest E:\WeFlowBridge\tests\test_project_contracts.py`
