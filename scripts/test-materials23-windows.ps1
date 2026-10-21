param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-materials23-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/materials23.cfg" "$test/ftebroom/materials23.cfg"
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','materials23.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(65000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=[IO.File]::ReadAllText("$test/ftebroom/qconsole.log")
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_TRANSFORM_FAIL|CSQC_Abort|runaway loop' -or ([regex]::Matches($log,'FTEBROOM_TRANSFORM_PASS')).Count -ne 10){throw "Material checks failed: $test"}
$before=[IO.File]::ReadAllText("$test/ftebroom/maps/materials23.map")
$after=[IO.File]::ReadAllText("$test/ftebroom/maps/materials23-reloaded.map")
if($before -ne $after){throw "MAP round-trip differs: $test"}
Write-Host "PASS: 10 material checks and exact MAP round-trip. Results: $test/ftebroom"
