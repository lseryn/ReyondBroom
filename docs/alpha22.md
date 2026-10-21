# Background builds and BSP preview

[Русский](alpha22.ru.md)

Open **Run → Build map…** or press **F9**. Configure the Quake 3 `baseq3` directory in Game / resources and enter the path to your `q3map2.exe` in Build map. The compiler is an external dependency; it is not bundled.

Select the stages to execute:

- **Geometry / BSP** exports the current document to a separate snapshot and builds geometry with `-meta`.
- **Visibility / VIS** calculates visibility from the portal file. The map must be sealed.
- **Lighting / LIGHT** calculates lightmaps.

Export always precedes the selected compiler stages. The source MAP is never overwritten. A build uses the document state at export time, including unsaved edits and export-layer exclusions. You can continue editing while the external compiler runs. Loading a finished BSP and exporting the snapshot may briefly occupy the main thread.

When Geometry is disabled, VIS/LIGHT reuse the last successful build of the same document **only if the exported MAP is byte-identical**. Any MAP change, including light entity edits, requires Geometry in this version. Changes to external shader resources are not detected automatically; enable Geometry when uncertain. Stage choices and the compiler path are saved after starting a build.

The bottom of the perspective viewport shows the current stage, elapsed time, recent compiler output, Cancel and Log. The bar counts completed stages; it is **not a time estimate or a fabricated compiler percentage**. Full output is also saved as `build.log` in the build directory. Cancellation stops the process tree; errors and cancellation retain the previous successful BSP.

Press **Show BSP** after success. The editor temporarily uses one perspective pane, with the existing camera, to render the compiled world, baked lighting and stationary brush submodels. **Back to editing** restores the previous layout, source geometry, selection and history. Editing commands resume editing automatically; saving exits preview before saving the source. Automatic backups wait until editing resumes. The viewport labels an earlier document revision when the source has changed since export.

This is a visual preview, not gameplay: doors do not move, triggers do not fire, and gameplay-spawned entities are not simulated. The preview uses the currently mounted project resources. A Geometry-only build has no newly calculated lighting. Build and preview metadata are session-local; after restarting, build again before Show BSP becomes available.

Generated files live under `ftebroom/maps/ftebroom-build/<build-id>/` in the editor installation. Each attempt has a separate directory, including BSP, exported MAP, compiler sidecars and log. Completed build directories are retained for inspection; remove old directories only after closing the editor.

## What to test

1. On a copy of a sealed map, run all three stages. Confirm the editor remains navigable and the viewport reports the stages and log.
2. Show BSP: check lightmaps, shadows, textures, sky and brush entities. Move the camera with WASD and RMB. There is no game simulation.
3. Return to editing: verify the original selection, tools, grid, multiple-pane layout and Undo/Redo. Save As and reopen the result.
4. Build Geometry only. Then run VIS only, LIGHT only, or both on the unchanged map. With no stages checked, Build must refuse to start.
5. Change the map and request LIGHT without Geometry: expect a request to rebuild Geometry. Build again with Geometry enabled.
6. Edit the source while compiling: the completed BSP should be labelled as an earlier revision. Open another map while compiling: the result must not replace that document.
7. Cancel a long build. Test a nonexistent compiler path and a leaking map with VIS enabled. Inspect the error log; the previous successful BSP should remain available.
8. Save while viewing BSP and reopen the saved MAP: it must contain editable source brushes, not a BSP entity dump.

The existing [editor regression checklist](checks-alpha21.md) still applies. This release does not claim that every roadmap acceptance criterion is complete.
