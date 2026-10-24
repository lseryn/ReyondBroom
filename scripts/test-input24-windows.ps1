param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-input24-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
Copy-Item "$src/tests/input24.cfg" "$test/ftebroom/input24.cfg"
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','input24.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)){Stop-Process -Id $p.Id;throw "Input timeout: $test"}
$log=[IO.File]::ReadAllText("$test/ftebroom/qconsole.log")
if($p.ExitCode -ne 0 -or $log -match 'FTEBROOM_UI_FAIL|CSQC_Abort|runaway loop'){throw "Input failed: $test"}
foreach($value in @(@('x',0.375),@('y',1.75))){
  $match=[regex]::Match($log,('"ftebroom_scale_'+$value[0]+'" is "([^"]+)"'))
  if(!$match.Success -or [math]::Abs([double]::Parse($match.Groups[1].Value,[cultureinfo]::InvariantCulture)-$value[1]) -gt 0.0001){throw "Scale input did not commit: $test"}
}
Write-Host "PASS: ImGui Scale X=0.375 and Y=1.75 through native input and command dispatch. Results: $test/ftebroom"
