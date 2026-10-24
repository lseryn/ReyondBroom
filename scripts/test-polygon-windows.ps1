param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-polygon-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/polygon47.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','polygon47.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(60000)){Stop-Process -Id $process.Id;throw "Polygon tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Polygon regression failed: $test"}
foreach($name in @('polygon47_convex_merge','polygon47_spawn_volume','polygon47_concave_partition','polygon47_reverse_winding','polygon47_reject_self_intersection','polygon47_collinear_point','polygon47_cut_preview','polygon47_cut_depth','polygon47_keep_cutout','polygon47_apply','polygon47_single_undo','polygon47_spawn_apply','polygon47_spawn_undo','polygon47_pointer_points','polygon47_click_close','polygon47_drag_point','polygon47_escape_drag','polygon47_reopen_contour','polygon47_remove_point','polygon47_cancel_tool','symmetry47_create','symmetry47_four_sides','symmetry47_single_undo','symmetry47_edit_sync','symmetry47_edit_single_undo','symmetry47_reverse_edit','symmetry47_reconfigure_rotation','symmetry47_reconfigure_undo','symmetry47_two_sides','polygon47_persistent_preview','symmetry47_reload_metadata','symmetry47_reload_sync')){if($log -notmatch "PASS $name"){throw "Missing assertion ${name}: $test"}}
Write-Host "PASS: $test"
