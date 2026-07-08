Dim shell, fso, here, exitCode
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
exitCode = shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & here & "\weflow_heartbeat.ps1""", 0, True)
WScript.Quit exitCode
