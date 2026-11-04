param([string[]]$Tags)
$S = Split-Path -Parent $MyInvocation.MyCommand.Path
foreach ($t in $Tags) {
    $log = Join-Path $S "rapid_$t\EVE-X-diag.log"
    "=== $t"
    $rows = Get-Content $log -Encoding UTF8 | ? { $_ -match ' SLOW (\S+) took ([\d\.]+) ms' } | Select -Skip 2 | % {
        $null = $_ -match ' SLOW (\S+) took ([\d\.]+) ms(?: \(thread CPU ~([\d\.]+) ms\))?'
        [pscustomobject]@{ n = $matches[1]; ms = [double]$matches[2]; cpu = $(if ($matches[3]) { [double]$matches[3] } else { $null }) }
    }
    $rows | Group-Object n | % {
        $v = $_.Group.ms; $c = @($_.Group | ? { $_.cpu -ne $null }).cpu
        "{0,-22} n={1,3}  max={2,6:N1}  avg={3,5:N1} ms{4}" -f $_.Name, $_.Count, ($v | Measure -Max).Maximum, ($v | Measure -Average).Average, $(if ($c) { "  (avg CPU {0:N1} ms)" -f ($c | Measure -Average).Average } else { "" })
    }
    Get-Content $log -Encoding UTF8 | Select-String 'STATS' | Select -Last 2 | % { ($_.Line -replace ' \| DPS:.*', '').Substring(20) }
}
