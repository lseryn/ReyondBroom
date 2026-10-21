# FTEBroom 0.5.0-alpha.17 — workspace and appearance

[Русский](alpha17.ru.md) · [Previous tools and complete regression checklist](checks-alpha16.md)

This update changes the editor interface. The geometry tools and MAP format remain the same as alpha.16.

## Workspace

- Dark panels use the TrenchBroom dark palette: panel RGB 50/50/50, controls 35/35/35, text 207/207/207 and blue highlight 62/112/205.
- **Tools**, **Tool options**, **Map** and **Material** are dockable panels. Drag a tab into the scene to float the panel; drag it onto another panel and use the docking guides to dock beside it or combine tabs. Floating panels remain inside the editor window.
- Drag the divider between docked panels to resize. Drag a floating panel's edges or bottom corner to resize it. The scene automatically fills the remaining central area; its existing one-to-four views and splitters still work.
- Map and Material start as tabs on the right. They can be separated, including placing Material along the bottom or on the opposite side.
- **Workspace → Lock panels** prevents accidental panel movement/resizing. **Workspace → Reset panel layout** restores the default arrangement without changing the map or the view count.
- Layout is saved to `ftebroom/workspace.ini`. Scale and lock preference are saved to `ftebroom/appearance.cfg`. They survive map changes and application restarts. Automated QA scenes intentionally do not save personal settings.

## Fonts and dialogs

Open **Workspace → Appearance / font scale…**. Choose 100%, 125%, 150%, 175% or 200%. The default text size is 17 pixels, up from 15. Each scale has a separately rasterized font, including Cyrillic on Windows; text is not an enlarged low-resolution bitmap. Spacing and existing panel dimensions scale together. Reset UI scale restores 100% without resetting the panel arrangement.

Preferences, project setup, Move Objects, Move Camera, Select by Line, confirmation and error dialogs can now be resized. The existing file browser, action reference and material replacement windows remain resizable. Small windows can scroll when their content does not fit. Main menu, quick toolbar and status strip stay attached to the editor edges.

Material thumbnail labels now follow the dark text color. Surface attributes are in a collapsible section to leave more space for the texture browser.

## Verification and manual checks

Automated tests cover divider dragging, scene hit testing, floating-panel input capture, font scaling, restoring preferences/layout in a second engine process, resetting the layout and unchanged complete MAP output. Existing layout, action, material, transform and extrusion checks supplement these tests. Actual engine screenshots are inspected.

Please check on your monitor:

1. Open a copy of a map. Drag the Map/Material divider; verify selection, brush creation, movement, Clip and camera navigation in the resized scene.
2. Drag Material's tab out, resize the floating panel, then dock it below the scene. Click, scroll and type inside it: the brush behind it must not change and the camera must not move.
3. Recombine Map and Material as tabs. Try a four-view layout and drag its dividers; verify picking in all views.
4. Try 100%, 125%, 150% and 200%. Check legibility, Cyrillic filenames, tool buttons, material names and Preferences. At large scales on a small display, use scrolling or widen a panel.
5. Resize Preferences, Open/Save As and a numeric dialog. Confirm Escape/Cancel still works; do not overwrite an original map during this check.
6. Enable Lock panels, try moving/resizing panels, then unlock them. Reset the panel layout and reset the scale independently.
7. Change the layout and scale, close and reopen the editor, then open another map. Both preferences should remain. Reset layout if a floating panel is inconvenient after changing display resolution.
8. Create/move a brush, Undo/Redo, save to a new MAP and reopen. Geometry, material mapping and entity data should survive.

Separate OS windows, automatic Windows per-monitor DPI detection, custom color editing and named workspace presets are not included. Use the explicit UI scale control for high-DPI displays. This release does not complete the remaining geometry roadmap.
