param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python',[ValidateSet('document','preview','document-files')][string]$Case='document')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-'+$Case+'-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/$Case.cfg" "$test/ftebroom/$Case.cfg"
Copy-Item "$src/tests/fixtures/document.map" "$test/ftebroom/maps/document.map"
if($Case -eq 'document-files') {New-Item -ItemType Directory "$test/ftebroom/maps/files_fail.map" -Force | Out-Null}
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec',"$Case.cfg") -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)) {Stop-Process -Id $p.Id;throw "Test timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-$Case.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
