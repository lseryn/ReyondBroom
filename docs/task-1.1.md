# 3D camera — 0.5.0-alpha.8
[Combined manual checklist](checks-0.6-1.1.md)

## Controls

Use these controls over the scene in Perspective:

| Input | Result |
| --- | --- |
| Right drag | Look around, with pitch limited to ±89° and zero roll |
| Alt + right drag | Orbit the surface under the pointer; on a miss use a point 256 units ahead |
| Wheel during orbit | Change orbit radius, minimum 32 units |
| Wheel during ordinary right drag | Change flight speed by 5% per notch, limited to 100–10000 |
| Middle drag | Pan along the camera's right/up plane |
| Alt + middle drag | Optional forward pan, enabled in Preferences |
| WASD | Fly forward/back/left/right, including the vertical component of the view direction |
| Q / X | Move up/down along world Z |
| Shift / Alt while flying | Double / halve speed |
| Shift + wheel | Zoom field of view |
| Ctrl + Alt + Z | Reset zoom to the configured base FOV |
| Plain wheel | Grid by default; forward/back camera movement when the legacy grid option is disabled |
| Ctrl + Alt + wheel | Grid when no camera gesture is active |

Camera movement does not add history entries or modify the map. Text input, dialogs, brush gestures and Ctrl shortcuts suppress free flight. Escape ends a captured camera gesture. Ordinary WASD does not require holding a mouse button.

Preferences contains look/pan/wheel sensitivity, flight speed, base FOV, horizontal/vertical look inversion, wheel inversion, movement toward the cursor and optional Alt-middle behaviour. Movement/look sensitivity scales down with zoom; zooming out does not increase it above the base value. General preference persistence is a later roadmap item.

## Capture and saved views

`patches/relative-plugin-mouse.patch` implements the existing native API's null-cursor relative mode. It delivers relative motion as MenuEvent type 3, hides the cursor while captured, and restores its original position on release. The QC wrapper respects this capture instead of forcing the cursor visible each frame. Returning from another menu restores absolute cursor mode without reopening the editor over that menu.

Position, pitch, yaw and zoom are stored per map basename under `ftebroom/cameras/*.cam`. Files are updated while the workspace is active, before switching maps and on shutdown. Loading a map restores its saved view; a map without saved state uses the initial view. A repeated delayed startup position no longer overwrites movement. Camera files are separate from MAP/history. Two maps with the same basename share a camera entry.

## Verification and limits

`scripts/test-navigation-windows.ps1` launches two disposable engine instances in sequence. It checks 27 QC camera cases, 10 native input/capture cases, two restored-view assertions, unchanged MAP exports and actual engine screenshots. The native tests inject relative events through the same handler; physical mouse travel, cursor restoration, OS focus changes and DPI still require the manual checks.

The release also reruns existing document, editing, gesture, actions, tool lifecycle, history, grid, picking, geometry, project-resource and prepared-scene checks.

This stage concerns 3D navigation. Full 2D camera interaction and the orthographic background grid remain roadmap 1.2. Patch creation and unfinished modal tools are not added here.

![Camera preferences in the running engine](../screenshots/camera-preferences.png)
