<#
.SYNOPSIS  开启 Windows 自动登录 —— 让 GUI 程序(WeFlow/微信)真正"非登录"开机自启。
.DESCRIPTION
  关机重启后无人操作，Windows 自动登录该用户 → 进入交互会话 →
  "WeFlow Watchdog" / "WeChat AutoStart" 登录触发任务即可无人值守拉起。
  ⚠️ 安全取舍：密码会以**可逆方式存入注册表** HKLM\...\Winlogon。仅在物理安全的机器上使用。
.NOTES  以管理员运行。需要输入你的 Windows 登录密码（脚本不回显、不落盘明文）。
#>
param([string]$User = $env:USERNAME)
$ErrorActionPreference = 'Stop'
$pr = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $pr.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) { throw '请以管理员运行。' }

$sec = Read-Host "输入 $User 的 Windows 登录密码（用于自动登录）" -AsSecureString
$pw  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
$k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $k -Name AutoAdminLogon   -Value '1'
Set-ItemProperty $k -Name DefaultUserName  -Value $User
Set-ItemProperty $k -Name DefaultPassword  -Value $pw
Set-ItemProperty $k -Name DefaultDomainName -Value $env:USERDOMAIN
Write-Host "[OK] 已开启自动登录。重启后将自动登录 $User，WeFlow/微信 看门狗即可无人值守运行。" -ForegroundColor Green
Write-Host "撤销：把 AutoAdminLogon 设回 0 并删除 DefaultPassword。" -ForegroundColor DarkGray
