param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path $env:TEMP ('FTEBroom-tiles23-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/entity-tiles23.cfg" "$test/ftebroom/tiles23.cfg"
if(Test-Path "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','tiles23.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
& $Python -X utf8 "$src/tests/check-entity-tiles23.py" "$test/ftebroom"
if($p.ExitCode -ne 0 -or $LASTEXITCODE -ne 0){throw "Entity tiles failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
