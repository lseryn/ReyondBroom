param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-backups-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/backups.cfg" "$test/ftebroom/backups.cfg"
$originalHash=(Get-FileHash -LiteralPath "$test/ftebroom/maps/qa_clip.map").Hash
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','backups.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)) {Stop-Process -Id $p.Id;throw "Selection timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
if((Get-FileHash -LiteralPath "$test/ftebroom/maps/qa_clip.map").Hash -ne $originalHash){throw 'Backup changed original map'}
& $Python -X utf8 "$src/tests/check-backups.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Selection validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
