# Load a map directly in Warcraft III (war3.exe -loadfile) and report whether it crashes.
#   pwsh tools/wc3test.ps1 <map.w3x> [seconds]
# A crash writes a new "*Crash.txt" into the (VirtualStore) Errors folder; no crash within the timeout = OK.
param([Parameter(Mandatory)][string]$Map, [int]$Seconds = 40)
$war3 = "C:\Program Files\Warcraft III\war3.exe"
$errors = Join-Path $env:LOCALAPPDATA "VirtualStore\Program Files\Warcraft III\Errors"
$map = (Resolve-Path $Map).Path
$start = Get-Date
$p = Start-Process -FilePath $war3 -ArgumentList @("-window", "-loadfile", "`"$map`"") -PassThru
$result = "OK"
for ($i = 0; $i -lt $Seconds; $i++) {
    Start-Sleep -Seconds 1
    $crash = Get-ChildItem $errors -Filter "*Crash.txt" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $start }
    if ($crash) { $result = "CRASH"; break }
    if ($p.HasExited) { $result = "EXITED"; break }
}
Get-Process war3 -ErrorAction SilentlyContinue | Stop-Process -Force
"{0}`t{1}" -f $result, (Split-Path $map -Leaf)
