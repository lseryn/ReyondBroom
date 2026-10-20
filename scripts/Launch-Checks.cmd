@echo off
cd /d "%~dp0"
echo FTEBroom roadmap checks - Clip fix and 1.2 orthographic views
echo Close other FTEBroom windows before starting a check.
echo 1. Perspective: nearest red brush
echo 2. 2D front view: smaller blue brush
echo 3. Curved patch and point entity
echo 4. Clip, materials, move, delete and Undo/Redo
echo 5. 3D camera, orbit, pan, zoom and saved viewpoint
echo 6. Orthographic views: pan, zoom, grid and brush depth
choice /c 123456 /n /m "Choose a scene (1-6): "
set "QA_SCENE=qa-perspective"
if errorlevel 2 set "QA_SCENE=qa-2d"
if errorlevel 3 set "QA_SCENE=qa-patch"
if errorlevel 4 set "QA_SCENE=qa-clip"
if errorlevel 5 set "QA_SCENE=qa-camera"
if errorlevel 6 set "QA_SCENE=qa-views"
start "FTEBroom checks" fteqw64.exe -nohome -basedir "%~dp0." -window -width 1280 -height 800 +exec %QA_SCENE%.cfg
