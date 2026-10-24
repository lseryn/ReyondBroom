param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-conversion-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/conversion50.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','conversion50.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(60000)){Stop-Process -Id $process.Id;throw "Conversion tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Conversion regression failed: $test"}
foreach($name in @('conversion50_face_segments','conversion50_face_orientation_volume','conversion50_rotated_grid','conversion50_auto_texture_face','conversion50_subdivision_cancel','conversion50_independent_brushes','conversion50_group_cluster','conversion50_single_undo','conversion50_redo','conversion50_empty_space_rejected','subdivision44_texture_cell_scale','subdivision44_texture_volume','conversion50_rock_per_source_group','conversion50_rock_cancel','conversion50_rock_entity_protected')){if($log -notmatch "PASS $name"){throw "Missing assertion ${name}: $test"}}
foreach($name in @('undo','redo','branch','history_budget','defaults')){if(([regex]::Matches($log,"DESKTOP_PASS generator50_$name")).Count -ne 8){throw "Missing native settings history checks: $name"}}
Write-Host "PASS: $test"
