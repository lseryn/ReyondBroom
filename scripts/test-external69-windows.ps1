param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path $env:TEMP ('ReyondBroom-external69-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination "$test/editor" -Recurse
Copy-Item "$src/runtime/*" "$test/editor/ftebroom" -Recurse -Force
Copy-Item "$src/csaddon.dat" "$test/editor/ftebroom/csaddon.dat" -Force
& $Python -X utf8 "$src/tests/make-external69-fixture.py" $test
if($LASTEXITCODE){throw 'Fixture failed'}
$engine="$test/editor/bin/fteqw64.exe";if(!(Test-Path $engine)){$engine="$test/editor/fteqw64.exe"}
foreach($cfg in @('external69.cfg','external69-restart.cfg')){
 $p=Start-Process $engine -ArgumentList @('-nohome','-noupdates','-window','-width','1280','-height','800','-condebug','+exec',$cfg) -WorkingDirectory "$test/editor" -WindowStyle Hidden -PassThru
 if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw "External resources timeout: $test"}
 if($p.ExitCode){throw "Engine failed: $test"}
}
& $Python -X utf8 "$src/tests/check-external69.py" $test
if($LASTEXITCODE){throw "Resource regression: $test"}
Write-Host "PASS: $test"
