Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""E:\WeFlowBridge\weflow_heartbeat.ps1""", 0, False
