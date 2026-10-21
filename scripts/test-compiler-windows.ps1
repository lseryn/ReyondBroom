param([Parameter(Mandatory=$true)][string]$Bundle,[Parameter(Mandatory=$true)][string]$Compiler)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-compiler-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
$compilerPath=(Resolve-Path -LiteralPath $Compiler).Path.Replace('\','/')
if($compilerPath.Contains('"')){throw 'Unsupported quote in compiler path'}
@"
exec qa-clip.cfg
set ftebroom_test_compiler "$compilerPath"
in 12 ftebroom_test_run 6
in 30 ftebroom_test_run 7
in 31 screenshot compiler.png
in 33 quit force
"@ | Set-Content "$test/ftebroom/compiler.cfg" -Encoding utf8
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','compiler.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(55000)){Stop-Process -Id $p.Id;throw "Compiler timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($p.ExitCode -ne 0 -or $log.Contains('FTEBROOM_RUN_FAIL') -or !$log.Contains('FTEBROOM_RUN_PASS real_q3map2_bsp') -or !$log.Contains('FTEBROOM_RUN_PASS real_q3map2_profile')){throw "Compiler check failed: $test"}
Write-Host "PASS: actual q3map2 profile produced BSP. Results: $test/ftebroom"
