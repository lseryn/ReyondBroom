param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-scale-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/scale.cfg" "$test/ftebroom/scale.cfg"
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','scale.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)) {Stop-Process -Id $p.Id;throw "Selection timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-scale.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Selection validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"


