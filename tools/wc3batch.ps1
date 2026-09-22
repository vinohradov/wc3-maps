# Run wc3test-style load checks for every *.w3x in a folder (run elevated so war3 can be closed).
#   powershell -File tools/wc3batch.ps1 <folder> <results.txt> [seconds]
param([Parameter(Mandatory)][string]$Folder, [Parameter(Mandatory)][string]$Out, [int]$Seconds = 30)
$war3 = "C:\Program Files\Warcraft III\war3.exe"
# elevated war3 writes to the real folder, normal war3 to VirtualStore
$errors = @("C:\Program Files\Warcraft III\Errors", "C:\Users\vinog\AppData\Local\VirtualStore\Program Files\Warcraft III\Errors")
"" | Set-Content $Out
# NEVER kill a game the user is playing: refuse to run if Warcraft is already open.
if (Get-Process war3 -ErrorAction SilentlyContinue) {
    Add-Content $Out "ABORTED`tWarcraft is already running (user may be playing) - not touching it"
    Add-Content $Out "DONE"
    exit 0
}
Start-Transcript -Path "$Out.log" -Force | Out-Null
foreach ($m in Get-ChildItem $Folder -Filter "zz_*.w3x" | Sort-Object Name) {
    $start = Get-Date
    $p = Start-Process -FilePath $war3 -ArgumentList @("-window", "-loadfile", "`"$($m.FullName)`"") -PassThru
    $result = "OK"
    for ($i = 0; $i -lt $Seconds; $i++) {
        Start-Sleep -Seconds 1
        $crash = Get-ChildItem -Path $errors -Filter "*Crash.txt" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $start }
        if ($crash) { $result = "CRASH"; break }
        if ($p.HasExited) { $result = "EXITED"; break }
    }
    Get-Process war3 -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Add-Content $Out ("{0}`t{1}" -f $result, $m.Name)
}
Add-Content $Out "DONE"
Stop-Transcript | Out-Null
