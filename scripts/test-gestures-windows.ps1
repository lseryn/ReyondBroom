param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-gestures-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/gestures.cfg" "$test/ftebroom/gestures.cfg"
Get-ChildItem "$test/ftebroom/maps/gestures_*.map" -ErrorAction SilentlyContinue | Remove-Item
foreach($name in @('qconsole.log','gestures.png')) {
    $path=Join-Path "$test/ftebroom" $name
    if(Test-Path -LiteralPath $path) {Remove-Item -LiteralPath $path}
}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','gestures.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)) {Stop-Process -Id $p.Id;throw "Gestures timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-gestures.py" "$test/ftebroom/maps"
if($LASTEXITCODE -ne 0) {throw "Gestures validation failed: $test"}
Write-Host "PASS: gesture regression. Results: $test/ftebroom"
