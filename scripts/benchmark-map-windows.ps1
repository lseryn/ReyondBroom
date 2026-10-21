param([Parameter(Mandatory=$true)][string]$Bundle,[Parameter(Mandatory=$true)][string]$MapPath)
$ErrorActionPreference='Stop'
$map=(Resolve-Path -LiteralPath $MapPath).Path
$before=(Get-FileHash -LiteralPath $map -Algorithm SHA256).Hash
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-benchmark-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item -LiteralPath $map -Destination "$test/ftebroom/maps/benchmark-input.map"
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
set cl_maxfps 0
set vid_vsync 0
in 8 mapedit maps/benchmark-input.map
in 15 set ftebroom_benchmark 1
in 25 screenshot benchmark.png
in 27 quit force
'@ | Set-Content "$test/ftebroom/benchmark.cfg"
if(Test-Path "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','benchmark.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(70000)){Stop-Process -Id $p.Id;throw "Benchmark timeout: $test"}
if($p.ExitCode -ne 0){throw "Engine failed: $test"}
if((Get-FileHash -LiteralPath $map -Algorithm SHA256).Hash -ne $before){throw 'Original map changed'}
$log=Get-Content "$test/ftebroom/qconsole.log"
if(!($log -match 'FTEBROOM_BENCHMARK')){throw "Missing measurement: $test"}
if($log -match 'mod by zero|runaway loop|overflowed'){throw "Runtime error: $test"}
$log | Select-String 'FTEBROOM_BENCHMARK'
Write-Host "Results: $test/ftebroom"
