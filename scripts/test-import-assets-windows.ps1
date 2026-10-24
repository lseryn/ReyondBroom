param([Parameter(Mandatory=$true)][string]$Bundle,[Parameter(Mandatory=$true)][string]$ExternalFolder,[string]$Python='python')
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-assets31-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
& $Python -X utf8 tests/make-alpha30-fixture.py $test
if($LASTEXITCODE){throw 'Fixture failed'}
$external=Join-Path $test 'Рабочий стол'
New-Item -ItemType Directory -Path $external | Out-Null
foreach($file in 'concrete_sh.wad','images.jpg','images.png'){Copy-Item -LiteralPath (Join-Path $ExternalFolder $file) -Destination $external}
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "$($test.Replace('\','/'))"
in 7 ftebroom_test_desktop assets31
in 15 screenshot assets31.png
in 18 quit force
"@ | Set-Content "$test/editor/ftebroom/assets31.cfg"
$p=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','assets31.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(55000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'FTEBROOM_DESKTOP_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'FTEBROOM_DESKTOP_PASS')).Count -ne 10){throw "Asset test failed: $test"}
$qBsp=Get-ChildItem "$test/editor" -Filter qbsp.exe -Recurse | Select-Object -First 1
Push-Location "$test/compiler"
try { & $qBsp.FullName unicode.map *> qbsp-test.log;if($LASTEXITCODE){throw "qbsp failed: $test"} } finally { Pop-Location }
& $Python -X utf8 tests/check-import-bsp.py "$test/compiler"
if($LASTEXITCODE){throw "BSP textures missing: $test"}
Write-Host "PASS: external Unicode WAD, real JPG/PNG, compiler texture pixels, metadata, collections and file operations. Results: $test"
