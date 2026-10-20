param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-actions-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/actions.cfg" "$test/ftebroom/actions.cfg"
Get-ChildItem "$test/ftebroom/maps/actions_*.map" -ErrorAction SilentlyContinue | Remove-Item
foreach($name in @('qconsole.log','actions.png')) {
    $path=Join-Path "$test/ftebroom" $name
    if(Test-Path -LiteralPath $path) {Remove-Item -LiteralPath $path}
}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','actions.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)) {Stop-Process -Id $p.Id;throw "Actions timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-actions.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Actions validation failed: $test"}
Write-Host "PASS: action regression. Results: $test/ftebroom"
