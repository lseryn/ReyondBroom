param([string]$Baseline,[string]$Bundle,[string]$MapPath,[int]$View=3,[string]$AssetPath="",[string]$Python="python")
$ErrorActionPreference='Stop'
$root=Join-Path ([IO.Path]::GetTempPath()) ('ReyondBroom-performance31-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
$hash=(Get-FileHash -LiteralPath $MapPath).Hash
foreach($kind in 'before','after') {
 $source=$Baseline
 $test=Join-Path $root $kind
 Copy-Item -LiteralPath (Resolve-Path $source).Path -Destination $test -Recurse
 if($kind -eq 'after'){
  Copy-Item "$Bundle/fteplug_ftebroom_x64.dll" "$test/fteplug_ftebroom_x64.dll" -Force
  Copy-Item "$Bundle/ftebroom/csaddon.dat" "$test/ftebroom/csaddon.dat" -Force
 }
 if($AssetPath){foreach($directory in @($test,"$test/ftebroom")){[IO.File]::WriteAllText("$directory/ftebroom-project.txt",$AssetPath)}}
 [IO.File]::WriteAllText("$test/ftebroom/qconsole.log","")
 Copy-Item -LiteralPath $MapPath -Destination "$test/ftebroom/maps/performance.map"
 @'
exec ftebroom.cfg
set ftebroom_skip_setup 1
set vid_vsync 0
set cl_maxfps 0
in 6 mapedit maps/performance.map
in 12 ftebroom_test_desktop hidefiles34
in 13 ftebroom_test_desktop windows31
in 14 ca_brush_view 3
in 15 ftebroom_camera_restore 0 0 1024 90 0 0 90
in 16 ftebroom
in 16 ca_show 1
in 17 ftebroom_benchmark 1
in 28 screenshot performance2d.png
in 30 quit force
'@ | Set-Content "$test/ftebroom/performance31.cfg"
 if($View -eq 0){$cfg=Get-Content "$test/ftebroom/performance31.cfg" -Raw;$cfg.Replace('ca_brush_view 3','ca_brush_view 0').Replace('ftebroom_camera_restore 0 0 1024 90 0 0 90','ftebroom_camera_restore 0 -160 96 0 90 0 90') | Set-Content "$test/ftebroom/performance31.cfg"}
 if($AssetPath){
  $cfg=Get-Content "$test/ftebroom/performance31.cfg" -Raw
  $cfg=[regex]::Replace($cfg,'(?m)^in (\d+) ',{param($m)'in '+([int]$m.Groups[1].Value+60)+' '})
  Set-Content "$test/ftebroom/performance31.cfg" $cfg
 }
 $p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','performance31.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
 if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw "Timeout: $test"}
 if($p.ExitCode){throw "Engine failed: $test"}
 if(!(Select-String -Path "$test/ftebroom/qconsole.log" -Pattern "FTEBROOM_BENCHMARK")){throw "Missing benchmark: $test"}
 Select-String -Path "$test/ftebroom/qconsole.log" -Pattern 'FTEBROOM_BENCHMARK|FTEBROOM_PROFILE|CSQC_Abort'
}
if((Get-FileHash -LiteralPath $MapPath).Hash -ne $hash){throw 'Source map changed'}
& $Python -X utf8 "$PSScriptRoot/../tests/check-performance-images.py" "$root/before/ftebroom/performance2d.png" "$root/after/ftebroom/performance2d.png"
if($LASTEXITCODE){throw "Incomparable capture: $root"}
Write-Host "Results: $root"
