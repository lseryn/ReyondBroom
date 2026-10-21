param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-issues-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/issues.cfg" "$test/ftebroom/issues.cfg"
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','issues.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)) {Stop-Process -Id $p.Id;throw "Selection timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-issues.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Selection validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 8 ftebroom_test_preferences_reload
in 10 quit force
'@ | Set-Content "$test/ftebroom/preferences-reload.cfg"
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','preferences-reload.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(40000)){Stop-Process -Id $p.Id;throw 'Preferences restart timed out'}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log.Contains('FTEBROOM_PREFS_FAIL restart') -or !$log.Contains('FTEBROOM_PREFS_PASS restart_restores_preferences')){throw 'Preferences restart failed'}
Write-Host 'PASS: preferences restored after restart'
