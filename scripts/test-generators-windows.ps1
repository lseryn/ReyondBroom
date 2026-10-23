param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$test=Join-Path $env:TEMP ('FTEBroom-generators-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$PSScriptRoot/../csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$PSScriptRoot/../tests/generators.cfg" "$test/ftebroom/generators.cfg"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','generators.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(45000)){Stop-Process -Id $process.Id;throw "Timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($process.ExitCode -or $log -match 'FTEBROOM_\w+_FAIL|CSQC_Abort' -or $log -notmatch 'PASS preview_cancel_restores_original'){throw "Generators failed: $test"}
Write-Host "PASS: convex bevel, per-brush clamp, terrain prisms, preview ownership/cancel and rotated grid. $test"
