param([string]$Baseline,[string]$Bundle,[string]$MapPath,[int]$View=3)
$ErrorActionPreference='Stop'
$root=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-performance31-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
$hash=(Get-FileHash -LiteralPath $MapPath).Hash
foreach($kind in 'before','after') {
 $source=if($kind -eq 'before'){$Baseline}else{$Bundle}
 $test=Join-Path $root $kind
 Copy-Item -LiteralPath (Resolve-Path $source).Path -Destination $test -Recurse
 Copy-Item -LiteralPath $MapPath -Destination "$test/ftebroom/maps/performance.map"
 @'
exec ftebroom.cfg
set ftebroom_skip_setup 1
set vid_vsync 0
set cl_maxfps 0
in 6 mapedit maps/performance.map
in 14 ca_brush_view 3
in 15 ftebroom_camera_restore 0 0 1024 90 0 0 90
in 17 ftebroom_benchmark 1
in 28 screenshot performance2d.png
in 30 quit force
'@ | Set-Content "$test/ftebroom/performance31.cfg"
 if($View -eq 0){$cfg=Get-Content "$test/ftebroom/performance31.cfg" -Raw;$cfg.Replace('ca_brush_view 3','ca_brush_view 0').Replace('ftebroom_camera_restore 0 0 1024 90 0 0 90','ftebroom_camera_restore 0 -160 96 0 90 0 90') | Set-Content "$test/ftebroom/performance31.cfg"}
 $p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','performance31.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
 if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
 if($p.ExitCode){throw "Engine failed: $test"}
 Select-String -Path "$test/ftebroom/qconsole.log" -Pattern 'FTEBROOM_BENCHMARK|FTEBROOM_PROFILE|CSQC_Abort'
}
if((Get-FileHash -LiteralPath $MapPath).Hash -ne $hash){throw 'Source map changed'}
Write-Host "Results: $root"
