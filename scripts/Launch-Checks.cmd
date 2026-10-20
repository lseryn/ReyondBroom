@echo off
cd /d "%~dp0"
echo FTEBroom roadmap checks - Clip, orthographic views and 1.3 layouts
echo Close other FTEBroom windows before starting a check.
echo 1. Perspective: nearest red brush
echo 2. 2D front view: smaller blue brush
echo 3. Curved patch and point entity
echo 4. Clip, materials, move, delete and Undo/Redo
echo 5. 3D camera, orbit, pan, zoom and saved viewpoint
echo 6. Orthographic views: pan, zoom, grid and brush depth
echo 7. Four views: linked pan, zoom, dividers and focus
echo 8. Object selection: Ctrl-click, paint, drill and groups
echo 9. Face selection: toggle, paint and coplanar flood
echo A. Selection rendering: bounds, dimensions, hover and locked layer
echo B. Extrude / Split / Stamp, Rotate, clipboard and materials
choice /c 123456789AB /n /m "Choose a scene (1-9, A or B): "
set "QA_SCENE=qa-perspective"
if errorlevel 2 set "QA_SCENE=qa-2d"
if errorlevel 3 set "QA_SCENE=qa-patch"
if errorlevel 4 set "QA_SCENE=qa-clip"
if errorlevel 5 set "QA_SCENE=qa-camera"
if errorlevel 6 set "QA_SCENE=qa-views"
if errorlevel 7 set "QA_SCENE=qa-layouts"
if errorlevel 8 set "QA_SCENE=qa-selection"
if errorlevel 9 set "QA_SCENE=qa-faces"
if errorlevel 10 set "QA_SCENE=qa-visual"
if errorlevel 11 set "QA_SCENE=qa-extrude"
start "FTEBroom checks" fteqw64.exe -nohome -basedir "%~dp0." -window -width 1280 -height 800 +exec %QA_SCENE%.cfg
