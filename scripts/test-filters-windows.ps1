param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-filters-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/filters.cfg" "$test/ftebroom/filters.cfg"
$export=(Join-Path $test 'exported map.map').Replace('\','/')
Add-Content "$test/ftebroom/filters.cfg" "in 17.5 ftebroom_test_filepath export `"$export`""
Add-Content "$test/ftebroom/filters.cfg" "in 18 ftebroom_test_filepath exportcheck `"$export`""
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','filters.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)) {Stop-Process -Id $p.Id;throw "Selection timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-filters.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Selection validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"


