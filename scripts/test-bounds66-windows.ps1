param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-bounds66-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat","$src/tests/bounds66.cfg" "$test/ftebroom/"
& $Python "$src/tests/make-bounds66-fixture.py" "$test/ftebroom/maps"
if($LASTEXITCODE){throw 'Fixture failed'}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+exec','bounds66.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
if($p.ExitCode){throw "Engine failed: $test"}
& $Python "$src/tests/check-bounds66.py" "$test/ftebroom"
if($LASTEXITCODE){throw "Occlusion failed: $test"}
Write-Host "PASS: $test"
