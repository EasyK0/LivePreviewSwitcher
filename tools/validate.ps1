param([string]$File)
$S = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Start-Process 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' -ArgumentList '/ErrorStdOut=UTF-8', '/Validate', "`"$File`"" -Wait -PassThru -NoNewWindow -RedirectStandardError "$S\val_err.txt" -RedirectStandardOutput "$S\val_out.txt"
"validate exit " + $p.ExitCode
Get-Content "$S\val_err.txt"
