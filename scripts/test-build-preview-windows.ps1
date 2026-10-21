param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Compiler,[string]$Python='python',[switch]$Dynamic)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-build-preview-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat" -Force
New-Item -ItemType Directory -Force "$test/baseq3" | Out-Null
Copy-Item "$src/runtime/textures" "$test/baseq3" -Recurse
[IO.File]::WriteAllText("$test/ftebroom-project.txt",$test.Replace('\','/')+'/baseq3')
[IO.File]::WriteAllText("$test/ftebroom/ftebroom-project.txt",$test.Replace('\','/')+'/baseq3')
& $Python "$src/tests/make-build-fixture.py" "$test/ftebroom/maps/build-fixture.map"
if($LASTEXITCODE -ne 0){throw 'Fixture generation failed'}
$compilerPath=''
if($Compiler){$compilerPath=(Resolve-Path -LiteralPath $Compiler).Path.Replace('\','/')}
if($Dynamic){
    New-Item -ItemType Directory -Force "$test/baseq3/scripts","$test/ftebroom/scripts" | Out-Null
    $shader=@'
textures/ftebroom/animated_test
{
 qer_editorimage textures/ftebroom/qa_blue.tga
 surfaceparm nolightmap
 {
  map textures/ftebroom/qa_blue.tga
  rgbGen wave sin 0.6 0.4 0 0.37
  tcMod scroll 0.23 0.11
 }
}
'@
    foreach($game in @('baseq3','ftebroom')){
        [IO.File]::WriteAllText("$test/$game/scripts/animated_test.shader",$shader)
        [IO.File]::WriteAllText("$test/$game/scripts/shaderlist.txt","animated_test")
    }
    $map="$test/ftebroom/maps/build-fixture.map"
    [IO.File]::WriteAllText($map,[IO.File]::ReadAllText($map).Replace('ftebroom/grid','ftebroom/animated_test'))
}
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_compiler "$compilerPath"
in 7 mapedit maps/build-fixture.map
in 10 setpos 160 -180 140 15 130 0
in 11 ftebroom_box -80 -80 24 48 48 48
in 12 mod_terrain_save "" build-before
in 14 ftebroom_test_build 0
in 15 screenshot build-progress.png
in 35 ftebroom_test_build 1
in 38 screenshot build-bsp.png
in 39 screenshot build-bsp-animated.png
in 40 ftebroom_test_build 2
in 42 mod_terrain_save "" build-after
in 43 screenshot build-edit.png
in 44 ftebroom_test_build 3
in 61 ftebroom_test_build 4
in 64 screenshot build-light-only.png
in 65 ftebroom_test_build 5
in 67 ftebroom_undo
in 68 mod_terrain_save "" build-undo
in 69 ftebroom_redo
in 70 mod_terrain_save "" build-redo
in 72 ftebroom_test_build 6
in 75 ftebroom_test_build 7
in 76 ftebroom_test_build 8
in 78 ftebroom_test_build 9
in 79 ftebroom_box 120 120 24 32 32 48
in 80 ftebroom_test_build 10
in 83 ftebroom_test_build 11
in 84 quit force
"@ | Set-Content "$test/ftebroom/build-preview.cfg" -Encoding utf8
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','build-preview.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(110000)){Stop-Process -Id $p.Id;throw "Build preview timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_BUILD_FAIL|CSQC_Abort|runaway loop|setmodel on readonly|Unable to load maps/ftebroom-build' -or ([regex]::Matches($log,'FTEBROOM_BUILD_PASS')).Count -ne 17){throw "Build preview failed: $test"}
$before=Get-Content "$test/ftebroom/maps/build-before.map" -Raw
foreach($name in @('build-after','build-redo','build-direct-save')){if((Get-Content "$test/ftebroom/maps/$name.map" -Raw) -ne $before){throw "Document changed after preview: $name ($test)"}}
if((Get-Content "$test/ftebroom/maps/build-undo.map" -Raw) -eq $before){throw "Undo did not survive preview: $test"}
Write-Host "PASS: full build, lit BSP preview, return, LIGHT-only, original geometry and Undo/Redo. Results: $test/ftebroom"
if($Dynamic){
    & $Python -X utf8 "$src/tests/check-animated-bsp.py" "$test/ftebroom"
    if($LASTEXITCODE -ne 0){throw "Shader animation did not advance: $test"}
}
