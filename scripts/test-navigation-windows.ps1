param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-navigation-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/tests/navigation.cfg","$src/tests/navigation-reopen.cfg" "$test/ftebroom"
foreach($phase in @('navigation','navigation-reopen')) {
 if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log"){Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
 $p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec',"$phase.cfg") -WorkingDirectory $test -WindowStyle Hidden -PassThru
 if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw "Navigation timeout: $test"}
 if($p.ExitCode -ne 0){throw "Engine failed: $test"}
 Copy-Item "$test/ftebroom/qconsole.log" "$test/ftebroom/$phase.log"
}
& $Python -X utf8 "$src/tests/check-navigation.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0){throw "Navigation checks failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
