# Logs LinkBuds S bud + case battery state every N seconds to CSV (read-only commands only).
param([int]$IntervalSec = 60, [int]$MaxMinutes = 300, [string]$Out = "C:\LinkBudsFlash\charge-log.csv")
$w = "C:\LinkBudsFlash\tool"
# keep the laptop awake while logging (ES_CONTINUOUS | ES_SYSTEM_REQUIRED); released when the process exits
Add-Type -Name P -Namespace KA -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void][KA.P]::SetThreadExecutionState([uint32]2147483649)
function Y($a) {
  $p = Start-Process "$w\yusen.exe" -ArgumentList $a -WorkingDirectory $w -NoNewWindow -Wait -PassThru `
       -RedirectStandardOutput "$w\lo.txt" -RedirectStandardError "$w\le.txt"
  (Get-Content "$w\lo.txt","$w\le.txt" -Raw) -join "`n"
}
function Parse($txt, $side) {
  $r = [ordered]@{}
  $seg = ($txt -split 'GET_MAIN_BATTERY_INFO') | Where-Object { $_ -match "\($side\)" } | Select-Object -First 1
  if (-not $seg -or $seg -cmatch '\): NG') { return $null }
  foreach ($k in @(@('cap','CAPACITY: (\d+)'),@('fg','FG SOC: (\d+)'),@('ui','UI SOC: (\d+)'),@('mv','BattaryVoltage: (\d+)'),
                   @('temp','ThermistorTemperature: ([\d.]+)'),@('state','Charger State: (\d+)'),@('dmp','DMP: (\d+)'))) {
    if ($seg -match $k[1]) { $r[$k[0]] = $Matches[1] } else { $r[$k[0]] = '' }
  }
  $r
}
if (-not (Test-Path $Out)) {
  "time,L_cap,L_fg,L_ui,L_mv,L_temp,L_state,L_dmp,R_cap,R_fg,R_ui,R_mv,R_temp,R_state,R_dmp,case_mv,case_pct" | Set-Content $Out -Encoding ascii
}
$end = (Get-Date).AddMinutes($MaxMinutes)
while ((Get-Date) -lt $end) {
  $b = Y "get mainbatinfo all"
  $c = Y "get batvol"
  $L = Parse $b 'LEFT'; $R = Parse $b 'RIGHT'
  $cmv = if ($c -match '\((\d+)mV\)') { $Matches[1] } else { '' }
  $cp  = if ($c -match 'CAPACITY: OK\s*\r?\n=> (\d+)') { $Matches[1] } else { '' }
  $lv = if ($L) { ($L.Values -join ',') } else { ',,,,,,' }
  $rv = if ($R) { ($R.Values -join ',') } else { ',,,,,,' }
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$lv,$rv,$cmv,$cp" | Add-Content $Out -Encoding ascii
  # stop early once both buds report full (state 4) for 3 consecutive readings
  $tail = Get-Content $Out -Tail 3
  if ($tail.Count -eq 3 -and ($tail | Where-Object { ($_ -split ',')[6] -eq '4' -and ($_ -split ',')[13] -eq '4' }).Count -eq 3) { break }
  Start-Sleep $IntervalSec
}
