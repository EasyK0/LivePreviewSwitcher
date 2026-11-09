# Rapid switching test: starts each preview exe in its own folder with a copy of your
# settings, runs tools\tester3.ahk against it at each interval and prints the results.
# Example:
#   powershell -File tools\rapid.ps1 -Exes dist\EVE-X-Preview-Ultimate.exe,dist\EVE-X-Preview-Test.exe `
#     -Labels Ultimate,Test -Config "$env:USERPROFILE\Desktop\EVE-X\EVE-X-Preview.json" -PreviewProfile <profile name>
# EVE clients of the chosen profile must be running. Results go to tools\rapid_result.txt (ignored by git).
param(
    [Parameter(Mandatory)][string[]]$Exes,
    [Parameter(Mandatory)][string[]]$Labels,
    [Parameter(Mandatory)][string]$Config,
    [string]$PreviewProfile = '',
    [int]$N = 60,
    [int[]]$Intervals = @(166, 100),
    [string]$Ahk = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
)
$S = Split-Path -Parent $MyInvocation.MyCommand.Path
$j2 = Get-Content $Config -Raw -Encoding UTF8
if ($PreviewProfile) {
    $j2 = [regex]::Replace($j2, '"LastUsedProfile":\s*"[^"]*"', ('"LastUsedProfile":"' + $PreviewProfile + '"'))
}
$res = Join-Path $S 'rapid_result.txt'
if (Test-Path $res) { [IO.File]::Delete($res) }
for ($i = 0; $i -lt $Exes.Count; $i++) {
    $T = Join-Path $S ('rapid_' + $Labels[$i])
    New-Item -ItemType Directory -Force $T | Out-Null
    Copy-Item $Exes[$i] (Join-Path $T 'evex.exe')
    [IO.File]::WriteAllText((Join-Path $T 'EVE-X-Preview.json'), $j2, [Text.UTF8Encoding]::new($false))
    $p = Start-Process (Join-Path $T 'evex.exe') -WorkingDirectory $T -PassThru
    Start-Sleep 5
    foreach ($iv in $Intervals) {
        Start-Process $Ahk -ArgumentList '/ErrorStdOut=UTF-8', "`"$S\tester3.ahk`"", $p.Id, "`"$res`"", $N, $iv, $Labels[$i] -Wait -NoNewWindow -RedirectStandardError "$S\re.txt" | Out-Null
        Get-Content "$S\re.txt"
        Start-Sleep 1
    }
    Start-Sleep 6
    Stop-Process -Id $p.Id -Confirm:$false
    Start-Sleep 1
}
Get-Content $res -Encoding UTF8
