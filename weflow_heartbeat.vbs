Dim shell, exitCode
Set shell = CreateObject("WScript.Shell")
exitCode = shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""E:\WeFlowBridge\weflow_heartbeat.ps1""", 0, True)
WScript.Quit exitCode
