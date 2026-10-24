param([Parameter(Mandatory=$true)][string]$Bundle, [string]$Engine, [switch]$ExpectCrash)
$ErrorActionPreference='Stop'
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-shader-reload-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
if($Engine){Copy-Item -LiteralPath (Resolve-Path $Engine).Path -Destination "$test/fteqw64.exe" -Force}
foreach($name in @('config.cfg','fte.cfg','qconsole.log')) {
    $path=Join-Path "$test/ftebroom" $name
    if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}
}
$shader="$test/ftebroom/glsl/ftebroom_grid.glsl"
$original=[IO.File]::ReadAllText($shader)
$replacement=$original -replace '(?m)^!!cvarf[^\r\n]*',''
@'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 8 echo SHADER_RELOAD_READY
in 14 set r_glsl_offsetmapping 1
in 17 echo SHADER_RELOAD_SURVIVED
in 18 quit
'@ | Set-Content "$test/ftebroom/shader-reload.cfg"
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-noupdates','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','shader-reload.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
$log="$test/ftebroom/qconsole.log"
$ready=$false
for($i=0;$i -lt 120;$i++) {
    if((Test-Path $log) -and (Select-String -LiteralPath $log -SimpleMatch 'SHADER_RELOAD_READY' -Quiet)){$ready=$true;break}
    if($p.HasExited){break}
    Start-Sleep -Milliseconds 250
}
if(!$ready){if(!$p.HasExited){Stop-Process -Id $p.Id};throw "Startup failed: $test"}
[IO.File]::WriteAllText($shader,$replacement)
if(!$p.WaitForExit(25000)){Stop-Process -Id $p.Id}
$survived=Select-String -LiteralPath $log -SimpleMatch 'SHADER_RELOAD_SURVIVED' -Quiet
if($ExpectCrash){
    $reports=Get-ChildItem -LiteralPath $test -Recurse -Filter '*crash.txt'
    $accessViolation=$reports | Select-String -SimpleMatch 'fatal exception 0xc0000005'
    if($survived -or !$accessViolation){throw "Expected access violation did not reproduce: $test"}
}
elseif(!$survived){throw "Shader reload failed: $test"}
Write-Host "PASS (ExpectCrash=$ExpectCrash): $test"
