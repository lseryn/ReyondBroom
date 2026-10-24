param([string]$Bundle)
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-crash31-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
Copy-Item "$test/ftebroom/maps/start.map" "$test/ftebroom/maps/crash-fixture.map"
$map="$test/ftebroom/maps/crash-fixture.map"
$hash=(Get-FileHash $map).Hash
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 6 mapedit maps/crash-fixture.map
in 10 echo CRASH_REPORT_CONSOLE_MARKER
in 12 ftebroom_test_desktop crash31
'@ | Set-Content "$test/ftebroom/crash31.cfg"
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-condebug','+exec','crash31.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
$report="$test/ftebroom/maps/crash-fixture_crash.txt"
try {
 $limit=(Get-Date).AddSeconds(40)
 do {
  Start-Sleep -Milliseconds 500
  $text=if(Test-Path $report){Get-Content $report -Raw}else{''}
 }while((Get-Date) -lt $limit -and $text -notmatch 'Build:')
 if($text -notmatch '0xc0000005' -or $text -notmatch 'CRASH_REPORT_CONSOLE_MARKER' -or $text -notmatch 'Recent editor commands:' -or $text -notmatch 'Build:'){throw "Incomplete native crash report: $test"}
 if((Get-FileHash $map).Hash -ne $hash){throw 'Map changed during crash test'}
 Write-Host "PASS: real fatal exception wrote context, console and native stack without changing the map. Report: $report"
}finally {if(!$p.HasExited){Stop-Process -Id $p.Id}}
