param(
    [int]$Chars = 14,
    [double]$Rate = 6,          # hits per second per character (steady)
    [int]$BurstEvery = 5,       # seconds between bursts (0 = none)
    [int]$BurstSize = 30,       # lines per burst per character
    [int]$Duration = 70,        # seconds
    [int]$StartDelay = 0,
    [int]$PrefillMB = 0,        # history written before start (MB per file)
    [int]$OneBurst = 0,         # if >0: write this many lines at once for char #1 at half time
    [string]$Tag = 'load',
    [string[]]$Names = @(),     # Listener names; use the names of your open EVE clients (default: Pilot 01, Pilot 02, ...)
    [string]$LogDir = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'EVE\logs\Gamelogs')
)
if (-not $Names) { $Names = 1..$Chars | % { 'Pilot {0:D2}' -f $_ } }
$names = $Names | Select -First $Chars
$dir = $LogDir
$enc = [Text.UTF8Encoding]::new($false)
$now = (Get-Date).ToUniversalTime()
$streams = @(); $paths = @()
$hitTpl = '[ {0} ] (combat) <color=0xff00ffff><b>{1}</b> <color=0x77ffffff><font size=10>to</font> <b><color=0xffffffff>Guristas Pillager</b><font size=10><color=0x77ffffff> - Federation Navy Large Plasma Smartbomb - Hits' + "`r`n"
$written = 0
try {
    Start-Sleep $StartDelay
    for ($i = 0; $i -lt $names.Count; $i++) {
        $p = Join-Path $dir ($now.ToString('yyyyMMdd_HHmmss') + '_99999' + ('{0:D4}' -f $i) + '.txt')
        $fs = [IO.FileStream]::new($p, 'CreateNew', 'Write', 'ReadWrite')
        $hdr = "------------------------------------------------------------`r`n  Gamelog`r`n  Listener: $($names[$i])`r`n  Session Started: $($now.ToString('yyyy.MM.dd HH:mm:ss'))`r`n------------------------------------------------------------`r`n"
        $b = $enc.GetBytes($hdr); $fs.Write($b, 0, $b.Length)
        if ($PrefillMB -gt 0) {
            $old = $enc.GetBytes(($hitTpl -f $now.AddHours(-3).ToString('yyyy.MM.dd HH:mm:ss'), 80))
            $n = [int]($PrefillMB * 1MB / $old.Length)
            $ms = [IO.MemoryStream]::new()
            for ($k = 0; $k -lt $n; $k++) { $ms.Write($old, 0, $old.Length) }
            $ms.WriteTo($fs); $ms.Dispose()
        }
        $fs.Flush()
        $streams += $fs; $paths += $p
    }
    $t0 = Get-Date; $acc = 0.0; $lastBurst = $t0; $oneDone = $false
    while (((Get-Date) - $t0).TotalSeconds -lt $Duration) {
        $ts = (Get-Date).ToUniversalTime().ToString('yyyy.MM.dd HH:mm:ss')
        $acc += $Rate * 0.2
        $steady = [math]::Floor($acc); $acc -= $steady
        $burst = 0
        if ($BurstEvery -gt 0 -and ((Get-Date) - $lastBurst).TotalSeconds -ge $BurstEvery) { $burst = $BurstSize; $lastBurst = Get-Date }
        $line = $enc.GetBytes(($hitTpl -f $ts, 100))
        for ($i = 0; $i -lt $streams.Count; $i++) {
            $cnt = $steady + $burst
            if ($OneBurst -gt 0 -and -not $oneDone -and $i -eq 0 -and ((Get-Date) - $t0).TotalSeconds -ge $Duration / 2) { $cnt += $OneBurst; $oneDone = $true }
            for ($k = 0; $k -lt $cnt; $k++) { $streams[$i].Write($line, 0, $line.Length) }
            $streams[$i].Flush()
            $written += $cnt
        }
        Start-Sleep -Milliseconds 200
    }
}
finally {
    foreach ($s in $streams) { $s.Close() }
    foreach ($p in $paths) { [IO.File]::Delete($p) }
    $left = @($paths | ? { Test-Path $_ }).Count
    "[$Tag] wrote $written hit lines to $($paths.Count) fake logs; removed, left: $left" | Out-File (Join-Path $PSScriptRoot "loadgen_$Tag.txt") -Encoding utf8
}
