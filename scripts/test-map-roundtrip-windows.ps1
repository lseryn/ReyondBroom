param([Parameter(Mandatory=$true)][string]$Bundle,[Parameter(Mandatory=$true)][string]$MapPath,[string]$Python='python',[switch]$RestartRenderer)
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$map=(Resolve-Path -LiteralPath $MapPath).Path
$before=(Get-FileHash -LiteralPath $map -Algorithm SHA256).Hash
$test=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-map-roundtrip-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
$engine=Join-Path $test "bin/fteqw64.exe"
if(!(Test-Path -LiteralPath $engine)){$engine=Join-Path $test "fteqw64.exe"}
Copy-Item "$src/csaddon.dat" "$test/ftebroom/csaddon.dat"
# Work from a private copy; never save over the caller's original map.
Copy-Item -LiteralPath $map -Destination "$test/ftebroom/maps/roundtrip-input.map"
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 10 mapedit maps/roundtrip-input.map
in 25 mod_terrain_save "" roundtrip-first
in 27 screenshot roundtrip.png
in 28 mapedit maps/roundtrip-first.map
in 40 exec roundtrip-check.cfg
'@ | Set-Content "$test/ftebroom/roundtrip.cfg"
@'
in 1 mod_terrain_save "" roundtrip-second
in 2 ftebroom_select all
in 5 ftebroom_selection_count
in 6 ftebroom_select invert
in 9 ftebroom_selection_count
in 11 quit force
'@ | Set-Content "$test/ftebroom/roundtrip-check.cfg"
if($RestartRenderer) {
    $cfg=Get-Content "$test/ftebroom/roundtrip.cfg" -Raw
    $cfg=$cfg.Replace('in 28 mapedit maps/roundtrip-first.map','in 28 ftebroom_renderer_restart')
    Set-Content "$test/ftebroom/roundtrip.cfg" $cfg
}
if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process $engine -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','roundtrip.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw "Round-trip timeout: $test"}
if($p.ExitCode -ne 0){throw "Engine failed: $test"}
if((Get-FileHash -LiteralPath $map -Algorithm SHA256).Hash -ne $before){throw 'Source map changed'}
& $Python -X utf8 "$src/tests/check-map-roundtrip.py" "$test/ftebroom"
if($LASTEXITCODE -ne 0){throw "Round-trip validation failed: $test"}
Write-Host "PASS. Original unchanged. Results: $test/ftebroom"
