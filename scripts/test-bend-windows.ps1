param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-bend-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/bend46.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','bend46.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(60000)){Stop-Process -Id $process.Id;throw "Bend tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Bend regression failed: $test"}
foreach($name in @('autosnap46_integral','autosnap46_one_undo','autosnap46_preserves_thin_brush','subtract46_regular_cells_volume','subtract46_source_materials','subtract46_single_undo','subtract46_redo','subtract46_rotated_fallback','subtract46_grid_budget_fallback','bend46_capture_straight','bend46_subdivision_volume','bend46_keep_joints_preview','bend46_scale_rotation','bend46_rigid_pieces','bend46_apply','bend46_single_undo','bend46_cancel_handle','bend46_cancel_tool','bend46_drag_preview','bend46_escape_drag','bend46_release_keeps_preview','bend46_local_undo','bend46_local_redo','bend46_gesture_cancel_tool')){if($log -notmatch "PASS $name"){throw "Missing assertion ${name}: $test"}}
Write-Host "PASS: $test"
