param(
    [Parameter(Mandatory=$true)][string]$Bundle,
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $Bundle).Path
$test = Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-project-' + [guid]::NewGuid())
Copy-Item -LiteralPath $source -Destination $test -Recurse
& $Python "$PSScriptRoot/../tests/prepare-project-fixture.py" $test
if ($LASTEXITCODE -ne 0) { throw 'Fixture preparation failed' }
$before = @(Get-ChildItem "$test/fixture assets/baseq3" -File -Recurse | ForEach-Object { (Get-FileHash $_.FullName).Hash })
$process = Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','test03.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if (!$process.WaitForExit(45000)) {
    Stop-Process -Id $process.Id
    throw "Project test timed out: $test"
}
if ($process.ExitCode -ne 0) { throw "Engine failed: $test" }
& $Python "$PSScriptRoot/../tests/check-project.py" "$test/ftebroom"
if ($LASTEXITCODE -ne 0) { throw "Project validation failed: $test" }
$after = @(Get-ChildItem "$test/fixture assets/baseq3" -File -Recurse | ForEach-Object { (Get-FileHash $_.FullName).Hash })
if (Compare-Object $before $after) { throw 'Source assets changed' }
Write-Host "PASS: source assets unchanged. Results: $test"
