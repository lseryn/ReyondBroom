param([string]$Bundle,[string]$MapPath,[string]$GameRoot,[string]$Python='python')
$ErrorActionPreference='Stop'
$before=(Get-FileHash -LiteralPath $MapPath).Hash
$t=Join-Path $env:TEMP ('ReyondBroom-patches32-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $t -Recurse
Copy-Item -LiteralPath $MapPath -Destination "$t/ftebroom/maps/patch-copy.map"
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 4 mapedit maps/patch-copy.map
in 14 ftebroom_export_map
in 17 quit force
'@ | Set-Content "$t/ftebroom/patch32.cfg"
Write-Host $t
$p=Start-Process "$t/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$t+'"'),'-window','-condebug','+exec','patch32.cfg') -WorkingDirectory $t -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw 'Timeout'}
$q=(Get-ChildItem $t -Recurse -Filter q3map2.exe | Select-Object -First 1).FullName
& $q -game quake3 -fs_basepath $GameRoot -fs_game baseq3 -meta -threads 4 "$t/ftebroom/data/export-map.map" *> "$t/q3-build.log"
if($LASTEXITCODE){throw "Compile failed: $t"}
& $Python -X utf8 tests/check-build-patches.py $MapPath "$t/ftebroom/data/export-map.bsp"
if($LASTEXITCODE){throw "Patch check failed: $t"}
if((Get-FileHash -LiteralPath $MapPath).Hash -ne $before){throw 'Original changed'}
Write-Host "PASS: source unchanged. $t"
