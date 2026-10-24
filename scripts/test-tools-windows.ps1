param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-tools-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/tools.cfg" "$test/ftebroom/tools.cfg"
Get-ChildItem "$test/ftebroom/maps/tools_*.map" -ErrorAction SilentlyContinue | Remove-Item
foreach($name in @('qconsole.log','tools.png')) {
    $path=Join-Path "$test/ftebroom" $name
    if(Test-Path -LiteralPath $path) {Remove-Item -LiteralPath $path}
}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','tools.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)) {Stop-Process -Id $p.Id;throw "Tools timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-tools.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Tools validation failed: $test"}
Write-Host "PASS: tool lifecycle regression. Results: $test/ftebroom"
