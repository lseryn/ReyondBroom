param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin',[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-folders-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/folders52.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','folders52.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(60000)){Stop-Process -Id $process.Id;throw "Unity tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Unity regression failed: $test"}
foreach($name in @('palette_formats','full_palette_mask','bmp_palette','png_resize','invalid_palette','async_wad','recursive_images','unique_names','registered_wad','compiler_staging','backup','cancel')){if($log -notmatch "PASS folders52_$name"){throw "Missing folder assertion ${name}: $test"}}
& $Python -X utf8 "$src/tests/check-folder-wad-compile.py" "$src/tools/ericw/qbsp.exe" "$test/ftebroom" "$src/runtime/maps/start.map"
if($LASTEXITCODE){throw "Compiled WAD pixel check failed: $test"}
Write-Host "PASS: $test"
