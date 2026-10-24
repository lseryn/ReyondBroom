param([Parameter(Mandatory=$true)][string]$Bundle,[Parameter(Mandatory=$true)][string]$LibreInstall,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-pak-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
New-Item -ItemType Directory -Path "$test/editor/downloads" -Force | Out-Null
Copy-Item -LiteralPath (Resolve-Path $LibreInstall).Path -Destination "$test/editor/downloads/librequake-v0.09" -Recurse
& $Python -X utf8 "$src/tests/make-quake1-pak-fixture.py" $test
if($LASTEXITCODE){throw 'Fixture failed'}
$editor="$test/editor"
$p=Start-Process "$editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$editor+'"'),'-window','-width','1280','-height','800','-condebug','+exec','pak-test.cfg') -WorkingDirectory $editor -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(100000)){Stop-Process -Id $p.Id;throw "PAK timeout: $test"}
$log=Get-Content "$editor/ftebroom/qconsole.log" -Raw
$latest=$log.Substring($log.LastIndexOf('execing pak-test.cfg'))
if($p.ExitCode -ne 0 -or $latest -match 'FTEBROOM_BUILD_FAIL|CSQC_Abort|ReyondBroom save failed' -or ([regex]::Matches($latest,'FTEBROOM_BUILD_PASS')).Count -ne 18){throw "PAK test failed: $test"}
$starter=Get-Content "$editor/ftebroom/maps/starter-quake1.map" -Raw
if(!$starter.Contains('info_player_start') -or $starter.Contains('info_player_deathmatch') -or $starter.Contains('ftebroom/grid')){throw 'Wrong starter map'}
& $Python -X utf8 "$src/tests/check-quake1-pak.py" "$test/id1/pak2.pak"
if($LASTEXITCODE){throw 'PAK preservation failed'}
Write-Host "PASS: PAK open/save/build, WAD discovery, Quake starter, LibreQuake definitions/model thumbnail. Results: $test"
