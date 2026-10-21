param([Parameter(Mandatory=$true)][string]$Bundle,[string]$Python='python')
$ErrorActionPreference='Stop'
$src=(Resolve-Path "$PSScriptRoot/..").Path
$test=Join-Path ([IO.Path]::GetTempPath()) ('FTEBroom-file-browser-'+[guid]::NewGuid())
Copy-Item -LiteralPath (Resolve-Path $Bundle).Path -Destination $test -Recurse
$outside=Join-Path $test 'Map projects/Карты тест'
New-Item -ItemType Directory -Path $outside -Force | Out-Null
Copy-Item "$src/tests/fixtures/document.map" "$outside/исходная карта.map"
$folder=$outside.Replace('\','/')
@"
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 7 ftebroom_test_filepath open "$folder/исходная карта.map"
in 10 ftebroom_test_filepath save "$folder/новая карта.map"
in 12 ftebroom_box 512 512 64 128 128 128
in 13 ftebroom_test_filepath current
in 15 ftebroom_test_filepath open "$folder/новая карта.map"
in 18 ftebroom_test_filepath save "$folder/round trip.map"
in 20 ftebroom_ui open
in 21 screenshot file-browser.png
in 22 ftebroom_test_filepath browserclick up 1
in 22.1 ftebroom_test_filepath browserclick up 2
in 23 screenshot file-browser-parent.png
in 24 ftebroom_test_filepath browserclick "Карты тест" 1
in 24.1 ftebroom_test_filepath browserclick "Карты тест" 2
in 24.2 ftebroom_test_filepath browserclick "Карты тест" 1
in 24.3 ftebroom_test_filepath browserclick "Карты тест" 2
in 25 screenshot file-browser-return.png
in 26 ftebroom_test_filepath browserclick "исходная карта.map" 1
in 26.1 ftebroom_test_filepath browserclick "исходная карта.map" 2
in 27 ftebroom_test_filepath browserclick primary 1
in 27.1 ftebroom_test_filepath browserclick primary 2
in 30 ftebroom_ui saveas
in 31 ftebroom_test_filepath name "через браузер.map"
in 32 screenshot file-browser-save.png
in 33 ftebroom_test_filepath browserclick primary 1
in 33.1 ftebroom_test_filepath browserclick primary 2
in 35 quit force
"@ | Set-Content "$test/ftebroom/file-browser.cfg" -Encoding utf8
if(Test-Path "$test/ftebroom/qconsole.log") {Remove-Item -LiteralPath "$test/ftebroom/qconsole.log"}
$p=Start-Process "$test/fteqw64.exe" -ArgumentList @('-nohome','-basedir',('"'+$test+'"'),'-window','-width','1280','-height','800','-condebug','+exec','file-browser.cfg') -WorkingDirectory $test -WindowStyle Hidden -PassThru
if(!$p.WaitForExit(45000)) {Stop-Process -Id $p.Id;throw "File browser timeout: $test"}
if($p.ExitCode -ne 0) {throw "Engine failed: $test"}
& $Python -X utf8 "$src/tests/check-file-browser.py" $test
if($LASTEXITCODE -ne 0) {throw "File browser regression failed: $test"}
Write-Host "PASS. Results: $test/ftebroom"
