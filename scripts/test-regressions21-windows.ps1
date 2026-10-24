param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-regressions21-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/regressions21.cfg" "$test/ftebroom/regressions21.cfg"
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
if(Test-Path "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','regressions21.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(50000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_OCCLUDED_FAIL|runaway loop|CSQC_Abort|mod by zero|shader.*error'){throw "Regression failed: $test"}
if(([regex]::Matches($log,'FTEBROOM_OCCLUDED_PASS')).Count -ne 6){throw "Missing checks: $test"}
if($log -notmatch 'FTEBROOM_OVERLAY_STRESS 400000 vertices'){throw "Missing overlay stress check: $test"}
Write-Host "PASS: occluded selection drag, cancellation, obstacle integrity and frontmost click. Results: $test/ftebroom"
