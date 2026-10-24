param([string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$t=Join-Path $env:TEMP ('ReyondBroom-terrain32-'+[guid]::NewGuid()); New-Item -ItemType Directory $t | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$t/editor" -Recurse
& $Python -X utf8 tests/make-terrain32-fixture.py $t
$p=Start-Process "$t/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$t+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','terrain32.cfg') -WorkingDirectory "$t/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(55000)){Stop-Process -Id $p.Id;throw "Timeout: $t"}
$log=Get-Content "$t/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'TERRAIN32_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'TERRAIN32_PASS')).Count -ne 6){throw "Terrain checks failed: $t"}
if($log -match 'TERRAIN34_FAIL' -or ([regex]::Matches($log,'TERRAIN34_PASS')).Count -ne 2){throw "Terrain exit checks failed: $t"}
if($log -match 'TERRAIN37_FAIL' -or $log -notmatch 'TERRAIN37_PASS profile_creation_guard'){throw "Terrain profile guard failed: $t"}
& $Python -X utf8 tests/check-terrain32.py $t
if($LASTEXITCODE){throw "Terrain preservation failed: $t"}
Write-Host "PASS: terrain creation, stroke Undo/Redo, creation Undo/Redo, save/reopen. $t"
