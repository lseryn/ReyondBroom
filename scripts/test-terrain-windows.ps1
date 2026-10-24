param([string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-terrain31-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
& $Python -X utf8 tests/make-alpha30-fixture.py $test
& $Python -X utf8 tests/make-terrain31-fixture.py $test
Copy-Item -LiteralPath "$test/id1/models" -Destination "$test/mod/models" -Recurse
$p=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','terrain31.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(55000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'FTEBROOM_TERRAIN_FAIL|CSQC_Abort|mod by zero' -or ([regex]::Matches($log,'FTEBROOM_TERRAIN_PASS')).Count -ne 2){throw "Terrain failed: $test"}
if(!(Test-Path "$test/mod/maps/saved-terrain")){throw "Terrain sections missing: $test"}
if((Get-Content "$test/mod/maps/saved-terrain.map" -First 1) -notmatch 'format=fte-terrain'){throw 'Terrain metadata lost'}
foreach($name in 'model-added','model-redo') {if((Get-Content "$test/editor/ftebroom/maps/$name.map" -Raw) -notmatch 'func_model'){throw "Model missing: $name"}}
if((Get-Content "$test/editor/ftebroom/maps/model-undo.map" -Raw) -match 'func_model'){throw 'Model Undo failed'}
Write-Host "PASS: terrain sculpt/save/reopen, sections, profile marker and model entity Undo/Redo. Results: $test"
