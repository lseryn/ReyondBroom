param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-filters66-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
foreach($name in @('config.cfg','fte.cfg','qconsole.log')) {
    $path=Join-Path "$test/ftebroom" $name
    if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}
}
Copy-Item "$src/runtime/default.cfg" "$test/ftebroom/default.cfg"
Copy-Item "$src/runtime/ftebroom.cfg" "$test/ftebroom/ftebroom.cfg"
$engine="$test/bin/fteqw64.exe"
if(!(Test-Path $engine)){$engine="$test/fteqw64.exe"}
Copy-Item "$src/tests/filters66*.cfg" "$test/ftebroom/"
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
foreach($cfg in @('filters66.cfg','filters66-restart.cfg')) {
    $p=Start-Process $engine -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec',$cfg) -WorkingDirectory $test -WindowStyle Hidden -PassThru
    if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
    if($p.ExitCode){throw "Engine failed: $test"}
}
& $Python "$src/tests/check-filters66.py" "$test/ftebroom/qconsole.log"
if($LASTEXITCODE){throw "Filter regression failed: $test"}
Write-Host "PASS: $test"
