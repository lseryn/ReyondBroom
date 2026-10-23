param([string]$Bundle,[string]$Wad,[string]$Python='python')
$ErrorActionPreference='Stop'
$before=(Get-FileHash -LiteralPath $Wad).Hash
$t=Join-Path $env:TEMP ('FTEBroom-wad32-'+[guid]::NewGuid());New-Item -ItemType Directory $t | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$t/editor" -Recurse
& $Python -X utf8 tests/make-quake1-fixture.py $t
& $Python -X utf8 tests/make-wad32-fixture.py $t $Wad
$p=Start-Process "$t/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$t+'/editor"'),'-window','-condebug','+exec','wad32.cfg') -WorkingDirectory "$t/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(65000)){Stop-Process -Id $p.Id;throw "Timeout: $t"}
$log=Get-Content "$t/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'DESKTOP_PASS')).Count -ne 4){throw "Build test failed: $t"}
& $Python -X utf8 tests/check-wad32-build.py $t
if($LASTEXITCODE){throw "WAD missing from real build: $t"}
if((Get-FileHash -LiteralPath $Wad).Hash -ne $before){throw 'Original WAD changed'}
Write-Host "PASS: source WAD unchanged. $t"
