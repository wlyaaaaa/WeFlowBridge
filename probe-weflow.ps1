# probe-weflow.ps1 —— WeFlow API 自检
# 从 .env 读取 base/token，依次探活并报告。不在脚本里硬编码任何密钥。

$ErrorActionPreference = 'Stop'
$envPath = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envPath)) { Write-Host "缺少 .env，请先复制 .env.example 为 .env 并填写。" -ForegroundColor Red; exit 1 }

# 解析 .env
$cfg = @{}
Get-Content $envPath | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    $cfg[$k.Trim()] = $v.Trim()
}
$base = $cfg['WEFLOW_BASE_URL']
$token = $cfg['WEFLOW_TOKEN']
if (-not $base) { $base = 'http://127.0.0.1:5031' }

$headers = @{}
if ($token -and $token -ne '__FILL_ME__') { $headers['Authorization'] = "Bearer $token" }

function Try-Get($name, $url) {
    try {
        $r = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 8
        Write-Host "[OK ] $name" -ForegroundColor Green
        return $r
    } catch {
        $code = $_.Exception.Response.StatusCode.value__ 2>$null
        Write-Host "[ERR] $name  -> $($_.Exception.Message)$(if($code){" (HTTP $code)"})" -ForegroundColor Red
        return $null
    }
}

Write-Host "Base: $base   Token: $(if($headers.Count){'已携带'}else{'未携带'})`n" -ForegroundColor Cyan

$h = Try-Get 'GET /health' "$base/health"
if ($null -eq $h) {
    Write-Host "`n服务可能未启动：WeFlow → 设置 → API 服务 → 启动服务。" -ForegroundColor Yellow
    exit 1
}

$s = Try-Get 'GET /api/v1/sessions?limit=3' "$base/api/v1/sessions?limit=3"
if ($s) { Write-Host "     会话数(本次返回): $($s.count) / 总计: $($s.total)" }

$c = Try-Get 'GET /api/v1/contacts?limit=3' "$base/api/v1/contacts?limit=3"
if ($c) { Write-Host "     联系人数(本次返回): $($c.count)" }

# 群成员（取第一个 @chatroom 会话）
$grp = $null
$grpSession = $null
if ($s -and $s.sessions) {
    $grpSession = $s.sessions | Where-Object { $_.username -like '*@chatroom' } | Select-Object -First 1
    if ($grpSession) { $grp = $grpSession.username }
}
if (-not $grp) {
    $moreSessions = Try-Get '取群id' "$base/api/v1/sessions?limit=30"
    if ($moreSessions -and $moreSessions.sessions) {
        $grpSession = $moreSessions.sessions | Where-Object { $_.username -like '*@chatroom' } | Select-Object -First 1
        if ($grpSession) { $grp = $grpSession.username }
    }
}
if ($grp) {
    $gm = Try-Get "GET /api/v1/group-members (群 $grp)" "$base/api/v1/group-members?talker=$grp"
    if ($gm) { Write-Host "     群成员数: $($gm.count)  fromCache=$($gm.fromCache)" }
}

# 朋友圈统计
$es = Try-Get 'GET /api/v1/sns/export/stats' "$base/api/v1/sns/export/stats"
if ($es) { Write-Host "     朋友圈: 总帖=$($es.data.totalPosts) 好友=$($es.data.totalFriends) 我的=$($es.data.myPosts)" }

# messages 不稳定：最新消息先不带日期探测，再给一次显式时间范围探测（仅判断当前能否取到，不输出正文）
if ($grp) {
    $latest = Try-Get "GET /api/v1/messages (群, 最新无日期)" "$base/api/v1/messages?talker=$grp&limit=5"
    if ($latest) {
        $items = @()
        if ($latest.messages) { $items = @($latest.messages) }
        elseif ($latest.data) { $items = @($latest.data) }
        $latestCount = if ($null -ne $latest.count) { $latest.count } else { $items.Count }
        Write-Host "     最新批次消息数: $latestCount（返回数组按 createTime 降序，最新在索引 0）"
        if ($items.Count -gt 0 -and $items[0].createTime) {
            $newest = [int64]$items[0].createTime
            $sessionLast = $grpSession.lastTimestamp
            Write-Host "     最新 createTime=$newest；session.lastTimestamp=$sessionLast；对齐=$($newest -eq [int64]$sessionLast)"
        }
    }
    $m = Try-Get "GET /api/v1/messages (群, 历史宽时间窗)" "$base/api/v1/messages?talker=$grp&start=20250101&end=20261231&limit=5"
    if ($m) { Write-Host "     历史窗口消息数: $($m.count)（为 0 属正常波动，多试几次/换会话）" }
}

Write-Host "`n自检完成。（端点基线：WeFlow 26.5.27 / 2026-06-20，换版本请复核）" -ForegroundColor Cyan
