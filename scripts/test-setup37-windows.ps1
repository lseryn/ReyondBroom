param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$test=Join-Path $env:TEMP ('FTEBroom-setup37-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
$root=$test.Replace('\','/')
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "$root/fixture"
in 8 ftebroom_test_desktop window37
in 9 ftebroom_test_desktop setup37
in 10 screenshot setup-language.png
in 12 ftebroom_test_desktop setup37profile
in 13 screenshot setup-profile.png
in 15 ftebroom_test_desktop setup37resources
in 16 screenshot setup-resources.png
in 18 ftebroom_test_desktop roots37
in 20 screenshot setup-roots.png
in 22 quit force
"@ | Set-Content "$test/ftebroom/setup37.cfg"
$process=Start-Process "$test/fteqw64.exe" -ArgumentList @('-window','-width','1280','-height','800','-nohome','-noupdates','-basedir',('"'+$test+'"'),'-condebug','+exec','setup37.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$process.WaitForExit(45000)){Stop-Process -Id $process.Id;throw "Setup timeout: $test"}
$log=Get-Content "$test/ftebroom/qconsole.log" -Raw
if($process.ExitCode -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or $log -notmatch 'DESKTOP_PASS return_to_mod_root'){throw "Setup failed: $test"}
Write-Host "PASS: window mode, wizard and separate file roots. $test"
