param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python',[string]$RuntimeMod)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-quake1-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
& $Python "$src/tests/make-quake1-fixture.py" $test
if($LASTEXITCODE){throw 'Fixture generation failed'}
if($RuntimeMod){
    Copy-Item ((Resolve-Path -LiteralPath $RuntimeMod).Path+'/*') "$test/id1" -Recurse -Force
    @'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 7 mapedit maps/build-fixture.map
in 9 ftebroom_camera_restore 0 -160 96 0 90 0 90
in 11 ftebroom_test_build 40
in 25 ftebroom_test_build 41
in 28 ftebroom_test_build 21
in 35 ftebroom_test_build 30
in 36 ftebroom_test_build 31
in 38 ftebroom_test_build 34
in 40 ftebroom_test_build 35
in 41 ftebroom_test_build 36
in 43 ftebroom_test_build 32
in 45 ftebroom_test_build 33
in 47 ftebroom_test_build 41
in 49 ftebroom_test_build 42
in 52 ftebroom_test_build 43
in 62 ftebroom_test_build 44
in 75 ftebroom_test_build 45
in 77 quit force
'@ | Set-Content "$test/editor/ftebroom/quake1-test.cfg"
}
$gameHash=(Get-FileHash -LiteralPath "$test/id1/test textures.wad").Hash
$editor="$test/editor"
$p=Start-Process "$editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$editor+'"'),'-window','-width','1280','-height','800','-condebug','+exec','quake1-test.cfg') -WorkingDirectory $editor -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(110000)){Stop-Process -Id $p.Id;throw "Quake 1 timeout: $test"}
$log=Get-Content "$editor/ftebroom/qconsole.log" -Raw
$latest=$log.Substring($log.LastIndexOf('execing quake1-test.cfg'))
$expected=8;if($RuntimeMod){$expected=10}
if($p.ExitCode -ne 0 -or $latest -match 'FTEBROOM_BUILD_FAIL|CSQC_Abort' -or ([regex]::Matches($latest,'FTEBROOM_BUILD_PASS quake1_')).Count -ne $expected){throw "Quake 1 failed: $test"}
if($RuntimeMod -and $latest -notmatch 'FTEBROOM_BUILD_PASS editor_camera_restored'){throw "Runtime preview failed: $test"}
if((Get-FileHash -LiteralPath "$test/id1/test textures.wad").Hash -ne $gameHash){throw 'Source WAD changed'}
$saved=Get-Content "$editor/ftebroom/maps/quake1-roundtrip.map" -Raw
if($saved.Contains('[') -or !$saved.Contains('"wad"')){throw 'Standard MAP format or WAD list was not preserved'}
Write-Host "PASS: WAD/palette/entities, QBSP/VIS/LIGHT, BSP29/BSP2, preview/return, LIGHT-only and standard MAP save. Results: $test"
