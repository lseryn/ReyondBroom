param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin',[string]$Config='model64',[Parameter(Mandatory=$true)][string]$Fixtures)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-setup-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/$Config.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
Copy-Item -LiteralPath (Resolve-Path $Fixtures).Path -Destination "$test/ftebroom/fixtures" -Recurse
New-Item -ItemType Directory -Force "$test/ftebroom/models/qa","$test/ftebroom/gfx" | Out-Null
Copy-Item "$Fixtures/halflife.mdl" "$test/ftebroom/models/qa/halflife.mdl"
$palette=New-Object byte[] 768
$palette[3]=255
$palette[7]=255
[IO.File]::WriteAllBytes("$test/ftebroom/gfx/palette.lmp",$palette)
Add-Content "$test/ftebroom/model64.cfg" ('set ftebroom_test_import_root "'+$test.Replace('\','/')+'/ftebroom"')
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec',"$Config.cfg") -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(150000)){Stop-Process -Id $process.Id;throw "Setup/fullscreen tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Setup/fullscreen regression failed: $test"}
$names=@('model64_blender_mdl_bounds_frames','model64_embedded_texture','model64_md3_texture_portable','model64_halflife_converted','model64_two_skins_detected','model64_skin_selection')
foreach($name in $names){if($log -notmatch "PASS $name"){throw "Missing assertion ${name}: $test"}}
Write-Host "PASS: $test"
