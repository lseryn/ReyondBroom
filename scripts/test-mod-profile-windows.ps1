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
$modHash=(Get-FileHash "$test/game/id1/progs.dat").Hash
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_mod "$posix/game/id1"
set ftebroom_test_engine "$posix/game/fteqw64.exe"
in 6 mapedit maps/build-fixture.map
in 9 ftebroom_test_build 20
in 10 ftebroom_test_build 0
in 40 ftebroom_test_build 21
in 55 ftebroom_test_build 22
in 57 ftebroom_test_build 23
in 59 screenshot profile.png
in 61 quit force
"@ | Set-Content "$test/editor/ftebroom/profile-test.cfg" -Encoding utf8
$p=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','profile-test.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_BUILD_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'FTEBROOM_BUILD_PASS')).Count -ne 5){throw "Profile test failed: $test"}
if((Get-FileHash $map).Hash -ne $mapHash -or (Get-FileHash "$test/game/id1/progs.dat").Hash -ne $modHash){throw 'Input files changed'}
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 5 ftebroom_test_build 24
in 6 quit force
"@ | Set-Content "$test/editor/ftebroom/profile-restart.cfg" -Encoding utf8
$p=Start-Process "$test/editor/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','profile-restart.cfg') -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(25000)){Stop-Process -Id $p.Id;throw "Restart timeout: $test"}
$log=Get-Content "$test/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_BUILD_FAIL' -or $log -notmatch 'profile_restored' -or $log -notmatch 'profile_option_restored'){throw "Persistence failed: $test"}
Write-Host "PASS: profile, build, runtime process, source preservation and restart. Inspect runtime appearance separately. Results: $test"
