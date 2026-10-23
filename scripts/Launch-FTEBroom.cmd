@echo off
cd /d "%~dp0"
start "FTEBroom" fteqw64.exe -nohome -noupdates -condebug -basedir "%~dp0." +exec ftebroom.cfg
