param([Parameter(Mandatory=$true)][string]$Launcher,[string]$MinGW='C:/msys64/mingw64/bin',[switch]$BinLayout)
$ErrorActionPreference='Stop'
$test=Join-Path $env:TEMP ('ReyondBroom launcher space '+[guid]::NewGuid()+' '+[char]0x416)
New-Item -ItemType Directory $test | Out-Null
Copy-Item -LiteralPath (Resolve-Path $Launcher).Path -Destination "$test/ReyondBroom.exe"
@'
#include <windows.h>
#include <shellapi.h>
#include <string>
static void write(const wchar_t* path,const std::wstring& text){HANDLE f=CreateFileW(path,GENERIC_WRITE,0,nullptr,CREATE_ALWAYS,0,nullptr);DWORD n;WriteFile(f,text.data(),text.size()*2,&n,nullptr);CloseHandle(f);}
int WINAPI wWinMain(HINSTANCE,HINSTANCE,PWSTR,int){wchar_t cwd[32768];GetCurrentDirectoryW(32768,cwd);write(L"cwd.txt",cwd);int n;auto args=CommandLineToArgvW(GetCommandLineW(),&n);std::wstring text;for(int i=0;i<n;i++)text+=std::wstring(args[i])+L"\n";LocalFree(args);write(L"args.txt",text);return 0;}
'@ | Set-Content "$test/probe.cpp"
$env:PATH="$MinGW;$env:PATH"
$build=Join-Path $env:TEMP ('launcher-probe-'+[guid]::NewGuid())
Copy-Item -LiteralPath "$test/probe.cpp" -Destination "$build.cpp"
& "$MinGW/g++.exe" -static -municode -mwindows "$build.cpp" -lshell32 -o "$build.exe"
if($LASTEXITCODE){throw 'Probe compilation failed'}
$engineDir=$test
if($BinLayout){$engineDir=Join-Path $test 'bin';New-Item -ItemType Directory $engineDir | Out-Null}
Copy-Item -LiteralPath "$build.exe" -Destination "$engineDir/fteqw64.exe"
if($BinLayout){Copy-Item -LiteralPath "$test/ReyondBroom.exe" -Destination "$test/fteqw64.exe"}
foreach($name in @('zlib1.dll','fteplug_ftebroom_x64.dll','libpng16.dll','libjpeg.dll','libgcc_s_seh-1.dll','libwinpthread-1.dll')){[IO.File]::WriteAllText((Join-Path $test $name),'preflight fixture')}
$process=Start-Process "$test/ReyondBroom.exe" -ArgumentList '+set launcher_probe "value with spaces"' -WorkingDirectory $env:TEMP -PassThru
if(!$process.WaitForExit(10000) -or $process.ExitCode){throw 'Launcher failed'}
$deadline=[DateTime]::UtcNow.AddSeconds(10)
while(!(Test-Path "$test/args.txt") -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 100}
$cwd=[IO.File]::ReadAllText("$test/cwd.txt",[Text.Encoding]::Unicode)
$args=[IO.File]::ReadAllLines("$test/args.txt",[Text.Encoding]::Unicode)
if($cwd -ne $test){throw 'Wrong working directory'}
if($BinLayout -and (Test-Path "$test/fteqw64.exe")){throw 'Compatibility alias was not removed'}
$index=[Array]::IndexOf($args,'-basedir')
if($index -lt 0 -or $args[$index+1] -ne $test){throw 'Base directory lost spaces or Unicode'}
if($args -notcontains 'ftebroom.cfg' -or $args -notcontains 'value with spaces'){throw 'Arguments were not preserved'}
Write-Host "PASS: GUI launcher, working directory, Unicode/spaces and argument forwarding ($test)"
