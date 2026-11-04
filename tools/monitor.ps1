param([int]$ProcId, [int]$Minutes = 60, [int]$Every = 20)
$S = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $S 'monitor.log'
Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;
public class WM{delegate bool P(IntPtr h,IntPtr l);[DllImport("user32")]static extern bool EnumWindows(P p,IntPtr l);[DllImport("user32")]static extern int GetWindowThreadProcessId(IntPtr h,out int pid);[DllImport("user32",CharSet=CharSet.Unicode)]static extern int GetClassName(IntPtr h,StringBuilder s,int n);[DllImport("user32")]static extern bool IsWindowVisible(IntPtr h);[DllImport("user32")]static extern bool IsHungAppWindow(IntPtr h);
public static string Check(int id){int dlg=0,hung=0,vis=0;EnumWindows((h,l)=>{int x;GetWindowThreadProcessId(h,out x);if(x==id){if(IsWindowVisible(h))vis++;var c=new StringBuilder(64);GetClassName(h,c,64);if(c.ToString()=="#32770"&&IsWindowVisible(h))dlg++;if(IsHungAppWindow(h))hung++;}return true;},IntPtr.Zero);return "visibleWindows="+vis+" errorDialogs="+dlg+" hungWindows="+hung;}}
'@
"$(Get-Date -Format 'HH:mm:ss') monitor start pid=$ProcId" | Out-File $log -Encoding utf8
$p = Get-Process -Id $ProcId -ErrorAction SilentlyContinue
$lastCpu = $p.TotalProcessorTime.TotalMilliseconds; $lastT = Get-Date
$end = (Get-Date).AddMinutes($Minutes)
$alerts = 0
while ((Get-Date) -lt $end) {
    Start-Sleep $Every
    $p = Get-Process -Id $ProcId -ErrorAction SilentlyContinue
    if (-not $p) { "$(Get-Date -Format 'HH:mm:ss') PROCESS EXITED" | Add-Content $log; break }
    $now = Get-Date; $cpu = $p.TotalProcessorTime.TotalMilliseconds
    $pct = ($cpu - $lastCpu) / ($now - $lastT).TotalMilliseconds * 100
    $lastCpu = $cpu; $lastT = $now
    $w = [WM]::Check($ProcId)
    $eve = @(Get-Process exefile -ErrorAction SilentlyContinue).Count
    $line = "{0} cpu {1:N2}% core | ws {2:N1} MB | handles {3} | threads {4} | {5} | EVE clients {6}" -f (Get-Date -Format 'HH:mm:ss'), $pct, ($p.WorkingSet64 / 1MB), $p.HandleCount, $p.Threads.Count, $w, $eve
    if ($w -notmatch 'errorDialogs=0' -or $w -notmatch 'hungWindows=0') { $line += '  <<< ALERT'; $alerts++ }
    $line | Add-Content $log
}
"$(Get-Date -Format 'HH:mm:ss') monitor end, alerts: $alerts" | Add-Content $log
Get-Content $log
