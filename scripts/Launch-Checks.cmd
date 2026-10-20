@echo off
cd /d "%~dp0"
echo FTEBroom roadmap 0.6 + 0.7 checks
echo Close other FTEBroom windows before starting a check.
echo 1. Perspective: nearest red brush
echo 2. 2D front view: smaller blue brush
echo 3. Curved patch and point entity
echo 4. Clip, materials, move, delete and Undo/Redo
choice /c 1234 /n /m "Choose a scene (1-4): "
set "QA_SCENE=qa-perspective"
if errorlevel 2 set "QA_SCENE=qa-2d"
if errorlevel 3 set "QA_SCENE=qa-patch"
if errorlevel 4 set "QA_SCENE=qa-clip"
start "FTEBroom checks" fteqw64.exe -nohome -basedir "%~dp0." -window -width 1280 -height 800 +exec %QA_SCENE%.cfg
