param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[string]$Python='python',[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-media-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
& $Python -X utf8 "$src/tests/make-media42-fixture.py" $test
if($LASTEXITCODE -ne 0){throw 'Cannot create media fixtures'}
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+exec','media42.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(70000)){Stop-Process -Id $process.Id;throw "Media tests timed out: $test"}
if($process.ExitCode -ne 0){throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-media42.py" $test
if($LASTEXITCODE -ne 0){throw "Media validation failed: $test"}
Write-Host "PASS. Results: $test"
