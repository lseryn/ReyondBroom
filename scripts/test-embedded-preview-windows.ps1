param(
    [Parameter(Mandatory=$true)][string]$Bundle,
    [Parameter(Mandatory=$true)][string]$RuntimeMod,
    [Parameter(Mandatory=$true)][string]$RuntimeEngine,
    [string]$Python='python'
)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-profile-'+[guid]::NewGuid())
New-Item -ItemType Directory "$test/game" -Force | Out-Null
Copy-Item -LiteralPath (Resolve-Path $RuntimeMod).Path -Destination "$test/game/id1" -Recurse
Copy-Item -LiteralPath (Resolve-Path $RuntimeEngine).Path -Destination "$test/game/fteqw64.exe"
$engineFolder=Split-Path (Resolve-Path $RuntimeEngine).Path
Get-ChildItem -LiteralPath $engineFolder -Filter '*.dll' | Copy-Item -Destination "$test/game"
if(Test-Path "$engineFolder/installed.lst"){Copy-Item "$engineFolder/installed.lst" "$test/game/installed.lst"}
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
$editorEngine="$test/editor/bin/fteqw64.exe"
if(!(Test-Path $editorEngine)){$editorEngine="$test/editor/fteqw64.exe"}
New-Item -ItemType Directory "$test/editor/baseq3" -Force | Out-Null
Copy-Item "$src/runtime/textures" "$test/editor/baseq3" -Recurse
Copy-Item "$src/runtime/textures/*" "$test/game/id1/textures" -Recurse -Force
$posix=$test.Replace('\','/')
foreach($path in @("$test/editor/ftebroom-project.txt","$test/editor/ftebroom/ftebroom-project.txt")){
    [IO.File]::WriteAllText($path,"$posix/editor/baseq3")
}
& $Python "$src/tests/make-build-fixture.py" "$test/editor/ftebroom/maps/build-fixture.map"
if($LASTEXITCODE){throw 'Fixture generation failed'}
$map="$test/editor/ftebroom/maps/build-fixture.map"
[IO.File]::WriteAllText($map,[IO.File]::ReadAllText($map).Replace('info_player_deathmatch','info_player_start'))
$mapHash=(Get-FileHash $map).Hash
'viewsize 50' | Set-Content "$test/game/id1/autoexec.cfg" -Encoding ascii
$modHash=(Get-FileHash "$test/game/id1/progs.dat").Hash
@'
ftebroom_test_filepath tap 450 250
ftebroom_test_build 37
ftebroom_test_filepath event escape 1 450 250
ftebroom_test_build 38
'@ | Set-Content "$test/editor/ftebroom/play-input.cfg" -Encoding utf8
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_autopreview 1
set ftebroom_test_mod "$posix/game/id1"
set ftebroom_test_engine "$posix/game/fteqw64.exe"
in 6 mapedit maps/build-fixture.map
in 8 ftebroom_camera_restore 0 -160 96 0 90 0 90
in 9 ftebroom_test_build 20
in 10 mod_terrain_save "" embedded-before
in 11 ftebroom_test_build 0
in 35 ftebroom_test_build 30
in 36 ftebroom_test_build 71
in 36.5 ftebroom_test_build 72
in 38 ftebroom_test_build 71
in 40 ftebroom_test_build 31
in 40.5 ftebroom_test_mod_controls 0
in 41 screenshot mod-controls64.png
in 41.2 ftebroom_test_mod_controls 1
in 41.5 ftebroom_test_mod_controls 2
in 42 ftebroom_test_build 34
in 44 ftebroom_test_build 35
in 45 exec play-input.cfg
in 46 ftebroom_test_build 36
in 50 ftebroom_test_build 32
in 52 ftebroom_test_build 33
in 53 mod_terrain_save "" embedded-after
in 55 quit force
"@ | Set-Content "$test/editor/ftebroom/profile-test.cfg" -Encoding utf8
$p=Start-Process $editorEngine -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','profile-test.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_BUILD_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'FTEBROOM_BUILD_PASS')).Count -ne 14){throw "Profile test failed: $test"}
if($log -match 'FTEBROOM_CONTROLS_FAIL' -or ([regex]::Matches($log,'FTEBROOM_CONTROLS_PASS')).Count -ne 4){throw "Controls menu test failed: $test"}
$play=Get-Content "$test/editor/ftebroom/embedded-play.log" -Raw
$positions=[regex]::Matches($play,'ftebroom_preview_player ([^\r\n]+)') | ForEach-Object {$_.Groups[1].Value}
if(($positions | Select-Object -Unique).Count -lt 2){throw "Player did not move: $test"}
if((Get-FileHash $map).Hash -ne $mapHash -or (Get-FileHash "$test/game/id1/progs.dat").Hash -ne $modHash){throw 'Input files changed'}
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_autopreview 1
in 5 ftebroom_test_build 24
in 6 quit force
"@ | Set-Content "$test/editor/ftebroom/profile-restart.cfg" -Encoding utf8
$p=Start-Process $editorEngine -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','profile-restart.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(150000)){Stop-Process -Id $p.Id;throw "Restart timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_BUILD_FAIL' -or $log -notmatch 'profile_restored' -or $log -notmatch 'profile_option_restored'){throw "Persistence failed: $test"}
if((Get-FileHash "$test/editor/ftebroom/maps/embedded-before.map").Hash -ne (Get-FileHash "$test/editor/ftebroom/maps/embedded-after.map").Hash){throw 'Document changed during preview'}
Write-Host "PASS: profile, build, embedded child, acknowledged camera, actual render camera, restoration and unchanged document. Results: $test"
