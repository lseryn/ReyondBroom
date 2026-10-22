param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-desktop-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
& $Python -X utf8 tests/make-alpha30-fixture.py $test
if($LASTEXITCODE){throw 'Fixture failed'}
$p=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','desktop-test.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'FTEBROOM_DESKTOP_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'FTEBROOM_DESKTOP_PASS')).Count -ne 9){throw "Desktop test failed: $test"}
& $Python -X utf8 tests/check-alpha30-pixels.py "$test/editor/ftebroom/model-tiles.png"
if($LASTEXITCODE){throw "Model pixels missing: $test"}
Write-Host "PASS: retro persistence, resize cursors, native file drop, image/WAD import and textured MDL/MD3. Results: $test"
