# =====================================================================
#  weflow_heartbeat.ps1 —— WeFlow API(5031) 看门狗
#  检查 5031 是否在线；挂了就拉起 WeFlow.exe（GUI 程序，需在用户会话中运行）。
#  微信(Weixin)稳定，本脚本不管它（由 WeChat AutoStart 任务在登录时拉起一次）。
#  日志: <project>\logs\weflow_heartbeat.log
# =====================================================================
$ErrorActionPreference = 'SilentlyContinue'
$root = $PSScriptRoot; if (-not $root) { $root = 'E:\Projects\Tools\WeFlowBridge' }
$logDir = Join-Path $root 'logs'; New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir 'weflow_heartbeat.log'
function Log([string]$m){ ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) | Out-File $log -Append -Encoding utf8 }

$exe  = 'C:\Program Files\WeFlow\WeFlow.exe'
$port = 5031

$c = Test-NetConnection -ComputerName '127.0.0.1' -Port $port -WarningAction SilentlyContinue
if ($c.TcpTestSucceeded) { Log "[OK] WeFlow API $port 健康"; exit 0 }

Log "[WARN] $port 无响应；尝试拉起 WeFlow.exe ..."
if (Get-Process WeFlow -ErrorAction SilentlyContinue) {
    Log "[INFO] WeFlow 进程在但端口未通 —— 可能 API 服务未开（WeFlow→设置→API 服务→启动）。不重复拉起。"
    exit 1
}
if (Test-Path $exe) {
    Start-Process -FilePath $exe
    Start-Sleep -Seconds 8
    $c2 = Test-NetConnection -ComputerName '127.0.0.1' -Port $port -WarningAction SilentlyContinue
    if ($c2.TcpTestSucceeded) { Log "[OK] WeFlow 已拉起，$port 恢复" } else { Log "[WARN] 已启动 WeFlow.exe，但 $port 暂未通（首启需手动在设置里开 API 服务一次）" }
} else { Log "[ERR] 找不到 $exe" }
