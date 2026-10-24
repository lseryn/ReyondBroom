param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$MinGW='C:/msys64/mingw64/bin',[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-reload-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
& $Python -X utf8 "$src/tests/prepare-reload-fixture.py" $test
if($LASTEXITCODE -ne 0){throw "Fixture failed"}
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+vid_width','1280','+vid_height','800','+exec','reload60.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(90000)){Stop-Process -Id $process.Id;throw "Setup/fullscreen tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($log -match 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow'){throw "Setup/fullscreen regression failed: $test"}
foreach($name in @('initialized','apply','finished','material_cache_preserved','entity_cache_preserved','shader_switch')){if($log -notmatch "PASS reload60_$name"){throw "Missing assertion ${name}: $test"}}
Write-Host "PASS: $test"
