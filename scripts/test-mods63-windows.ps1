param([Parameter(Mandatory=$true)][string]$Engine,[Parameter(Mandatory=$true)][string]$Plugin,[Parameter(Mandatory=$true)][string]$AD,[Parameter(Mandatory=$true)][string]$Libre,[string]$Python='python',[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-mods63-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item "$src/runtime" "$test/ftebroom" -Recurse
Copy-Item "$src/runtime/default.fmf","$src/runtime/installed.lst" $test
Copy-Item "$src/csaddon.dat" "$test/ftebroom/"
Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe"
Copy-Item -LiteralPath (Resolve-Path $Plugin).Path -Destination "$test/fteplug_ftebroom_x64.dll"
Copy-Item "$MinGW/zlib1.dll","$MinGW/libgcc_s_seh-1.dll","$MinGW/libwinpthread-1.dll" $test
Copy-Item "$MinGW/libpng16-16.dll" "$test/libpng16.dll"
Copy-Item "$MinGW/libjpeg-8.dll" "$test/libjpeg.dll"
& $Python -X utf8 "$src/tests/make-mods63-test.py" $test $AD $Libre
if($LASTEXITCODE){throw 'Test configuration failed'}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList '-nohome -noupdates -window -width 1280 -height 800 -condebug +exec mods63.cfg' -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw "Mod test timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log -match '_FAIL|CSQC_Abort|MAX_MOD_KNOWN'){throw "Mod test failed: $test"}
foreach($name in @('mods63_resources_ready','mods63_model_rendered','mods63_palette_and_materials','mods63_player_resource')) {
 if(([regex]::Matches($log,"PASS $name")).Count -ne 6){throw "Missing assertions ${name}: $test"}
}
if(([regex]::Matches($log,'FTEBROOM_REGISTRY_PASS')).Count -ne 2){throw "Missing registry assertions: $test"}
Write-Host "PASS: $test"
