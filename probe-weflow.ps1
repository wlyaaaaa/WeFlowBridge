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

Write-Host "`n自检完成。" -ForegroundColor Cyan
