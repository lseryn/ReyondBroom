param([string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$t=Join-Path $env:TEMP ('FTEBroom-ui34-'+[guid]::NewGuid())
New-Item -ItemType Directory $t | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$t/editor" -Recurse
& $Python -X utf8 tests/make-ui34-fixture.py $t
if($LASTEXITCODE){throw 'Fixture generation failed'}
$p=Start-Process "$t/editor/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$t+'/editor"'),'-window','-width','1280','-height','800','-condebug','+exec','ui34.cfg') -WorkingDirectory "$t/editor" -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)){Stop-Process -Id $p.Id;throw "Timeout: $t"}
$log=Get-Content "$t/editor/ftebroom/qconsole.log" -Raw
if($p.ExitCode -or ([regex]::Matches($log,'DESKTOP_PASS')).Count -ne 12 -or $log -match 'DESKTOP_FAIL|CSQC_Abort' -or $log -notmatch 'DESKTOP_PASS model_thumbnail_72k_vertices_valid_offsets'){throw "Large thumbnail test failed: $t"}
Write-Host "PASS: rendered textured model thumbnail beyond 65535 vertices; valid vertex offsets. $t"
