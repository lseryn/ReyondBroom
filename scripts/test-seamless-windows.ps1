param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$test=Join-Path $env:TEMP ('FTEBroom-seamless-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 9 ftebroom_test_desktop seamless36
in 11 screenshot seamless36.png
in 13 quit force
'@ | Set-Content "$test/ftebroom/seamless36.cfg"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-condebug','+exec','seamless36.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(40000)){Stop-Process -Id $process.Id;throw "Timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($process.ExitCode -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or $log -notmatch 'DESKTOP_PASS default_borderless_desktop_window'){throw "Seamless launch failed: $test"}
Write-Host "PASS: default borderless desktop window. $test"
