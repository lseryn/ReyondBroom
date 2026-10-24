param([string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$t=Join-Path $env:TEMP ('ReyondBroom-ui32-'+[guid]::NewGuid()); New-Item -ItemType Directory $t | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$t/editor" -Recurse
& $Python -X utf8 tests/make-ui32-fixture.py $t
$p=Start-Process "$t/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$t+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','ui32.cfg') -WorkingDirectory "$t/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)){Stop-Process -Id $p.Id;throw "Timeout: $t"}
$log=Get-Content "$t/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or ([regex]::Matches($log,'DESKTOP_PASS')).Count -ne 5){throw "UI checks failed: $t"}
Write-Host "PASS: file manager copy/move, new-map profile dialog and creation. $t"
