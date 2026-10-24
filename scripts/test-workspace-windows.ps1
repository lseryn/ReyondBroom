param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-workspace-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/workspace.cfg", "$src/tests/workspace-load.cfg" "$test/ftebroom"
foreach ($config in @('workspace.cfg', 'workspace-load.cfg')) {
    if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
    $p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec',$config) -WorkingDirectory $test -WindowStyle Hidden -PassThru
    if(!$p.WaitForExit(60000)) {Stop-Process -Id $p.Id;throw "Workspace timeout: $test"}
    if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
    Copy-Item "$test/ftebroom/qconsole.log" "$test/ftebroom/$config.log"
}
& $Python -X utf8 "$src/tests/check-workspace.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0) {throw "Workspace validation failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
