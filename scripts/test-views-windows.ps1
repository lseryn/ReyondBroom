param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-views-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/views.cfg" "$test/ftebroom/views.cfg"
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','views.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)) {Stop-Process -Id $p.Id;throw "Views timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-views.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Views validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
