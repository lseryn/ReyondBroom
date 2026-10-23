param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$test=Join-Path $env:TEMP ('FTEBroom-ui36-'+[guid]::NewGuid())
New-Item -ItemType Directory $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
& $Python -X utf8 tests/make-ui36-fixture.py $test
if($LASTEXITCODE){throw 'Fixture generation failed'}
$process=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','ui36.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(45000)){Stop-Process -Id $process.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($process.ExitCode -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or $log -notmatch 'DESKTOP_PASS audio_original_backup_retained'){throw "UI/audio test failed: $test"}
& $Python -X utf8 tests/check-ui36.py $test
if($LASTEXITCODE){throw "Audio validation failed: $test"}
Write-Host "PASS: UI and source audio replacement. Results: $test"
