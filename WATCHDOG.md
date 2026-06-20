# WeFlow 看门狗与自启

> 让 WeFlow API（5031）与微信开机/登录自启、挂死自愈。供 OpenClaw 等本机服务稳定取数。

## 计划任务（由 `weflow_boot_guardian.ps1` 注册）
| 任务 | 触发 | 作用 |
|------|------|------|
| **WeFlow Watchdog** | 登录 + 每 15 分钟 | 运行 `weflow_heartbeat.ps1`：5031 不通则拉起 `WeFlow.exe` |
| **WeChat AutoStart** | 登录 | 拉起 `Weixin.exe` 一次（微信稳定，无重启看门狗） |

## 安装
```powershell
# 管理员
powershell -ExecutionPolicy Bypass -File E:\WeFlowBridge\weflow_boot_guardian.ps1
```

## 关于"非登录运行"
WeFlow / 微信都是 **GUI 程序**，需要**交互会话**才能正常渲染与登录，所以看门狗用
**登录触发（Interactive）**——你登录（或开机自动登录）后即自动拉起。

要实现真正"关机重启后无人操作也运行"，需开 **Windows 自动登录**：
```powershell
powershell -ExecutionPolicy Bypass -File E:\WeFlowBridge\enable-autologin.ps1
```
> ⚠️ 自动登录会把密码以可逆方式存入注册表（`HKLM\...\Winlogon`），属安全取舍，仅在物理安全的机器上用。撤销：`AutoAdminLogon=0` 并删除 `DefaultPassword`。

## 排查
```powershell
Get-ScheduledTask 'WeFlow Watchdog','WeChat AutoStart' | Format-Table TaskName,State
Get-Content E:\WeFlowBridge\logs\weflow_heartbeat.log -Tail 20
powershell -File E:\WeFlowBridge\probe-weflow.ps1     # API 健康自检
```
> 注：WeFlow 的 API 服务首次需在 **WeFlow → 设置 → API 服务 → 启动服务** 打开一次（之后随 WeFlow 启动）。
