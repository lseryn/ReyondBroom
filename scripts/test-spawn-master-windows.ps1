param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-spawn-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat","$src/tests/spawn49.cfg" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','spawn49.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(60000)){Stop-Process -Id $process.Id;throw "Spawn Master tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Spawn Master regression failed: $test"}
foreach($name in @('spawn49_definition_cache','spawn49_create','spawn49_six_walls','spawn49_source_link','spawn49_destination_link','spawn49_single_undo','spawn49_redo','spawn49_shared_expansion','spawn49_unique_targets','spawn49_expansion_undo','spawn49_missing_destination','spawn49_invalid_class','spawn49_stale_selection','spawn49_reconfigure','spawn49_reload_metadata','spawn49_reload_reconfigure')){if($log -notmatch "PASS $name"){throw "Missing assertion ${name}: $test"}}
Write-Host "PASS: $test"
