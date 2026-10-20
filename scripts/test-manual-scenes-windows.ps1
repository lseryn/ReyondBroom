param([Parameter(Mandatory=$true)][string]$Bundle)
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-manual-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
foreach($scene in @('perspective','2d','patch','clip','camera','views')) {
    $cfg="exec qa-$scene.cfg`nin 12 ftebroom_test_manual $scene`nin 13 screenshot qa-$scene.png`n"
    if($scene -in @('camera','views')) {$cfg="exec qa-$scene.cfg`nin 12 mod_terrain_save `"`" qa_camera_smoke`nin 13 screenshot qa-$scene.png`n"}
    if($scene -eq 'patch') {$cfg+="in 14 ftebroom_test_manual entity`nin 15 screenshot qa-entity.png`n"}
    $cfg+="in 17 quit force`n"
    Set-Content "$test/ftebroom/manual.cfg" $cfg
    if(Test-Path -LiteralPath "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
    $p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','manual.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
    if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw "Timeout in $scene"}
    $log=Get-Content "$test/ftebroom/qconsole.log" -Raw
    if($p.ExitCode -ne 0 -or $log.Contains('FTEBROOM_MANUAL_FAIL')){throw "Manual scene failed: $scene, $test"}
    if($scene -in @('camera','views')) {
        $map=Get-Content "$test/ftebroom/maps/qa_camera_smoke.map" -Raw
        if(!$map.Contains('ftebroom/qa_blue') -or !(Test-Path "$test/ftebroom/qa-$scene.png")){throw 'Camera/view fixture failed'}
    } elseif(!$log.Contains("FTEBROOM_MANUAL_PASS $scene")) {throw "Manual scene failed: $scene, $test"}
    if($scene -eq 'patch' -and !$log.Contains('FTEBROOM_MANUAL_PASS entity')){throw 'Entity fixture failed'}
    Copy-Item "$test/ftebroom/qconsole.log" "$test/ftebroom/qa-$scene.log"
    Write-Host "PASS: $scene"
}
Write-Host "Manual scene screenshots: $test/ftebroom"
