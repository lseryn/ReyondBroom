# Alpha.23 — materials, entity tiles and animated BSP preview

[Русский](alpha23.ru.md)

## Materials and patches

Select a patch, open **Material** and click a material thumbnail. The patch keeps its texture while selected. Scale X, Scale Y, Angle and offsets now edit its control-point UVs, participate in Undo/Redo and survive MAP saves. Patch scale uses its parameter-space texture repeats, not brush pixel units. Existing non-affine UV detail is retained. Zero scale is rejected.

With nothing selected, Material fields set the mapping for the next brush. Selecting a curve patch activates **Control Point (P)**. The separate UV editor remains available.

## Entity browser

The Entity tab displays class tiles with colored bounds icons, a **Thumbnail size** slider, filters and grouping. Drag a point-entity tile into a viewport to place it. Click a different class while an entity is selected to change its class, keeping its origin, other properties and geometry. Point and brush classes cannot be interchanged this way; editor groups cannot be reclassified. Deselect first and double-click a tile to create at the displayed coordinates.

## Build and preview

The Windows package includes q3map2 under `tools/q3map2`, with its source and notices. **Build… / F9** opens options; **Build / Ctrl+F9** immediately compiles using the last settings. BSP, VIS and LIGHT remain individually selectable. Expand **Advanced compiler arguments** for per-stage options (for example LIGHT: `-fast -samples 3`). Arguments go directly to q3map2. A missing baseq3 directory opens resource setup. Save the map before building.

After a successful build, **F10** switches between BSP preview and editing. Supported Q3 shader animation now advances on a visual clock even while map-edit simulation is stopped. Shader view-dependent effects use the viewport camera. This does not run gameplay. Individual shader directives remain subject to FTE's support.

## Defaults and paths

- Hover highlight and sky surface overlays start disabled. Sky surfaces remain visible. View options can re-enable the overlays.
- The launcher starts a maximized, windowed editor.
- Modal dialogs have a close button; closing resource setup does not reopen it every frame.
- Save As updates the document directory, file browser and compile variables; resource reloads preserve the selected external path.
- Existing saved preferences and custom compiler paths remain respected.

## Manual checks

1. Create a curve patch; select it and confirm P activates. Change its material, both scales, angle and offsets. Confirm the selected patch is textured. Undo, Redo, save and reopen.
2. Deselect everything, set Material scale X/Y and angle, create a brush and inspect the resulting mapping.
3. Resize entity thumbnails and filter classes. Drag a point entity into perspective and 2D views. Select it, click another point class, then Undo/Redo. Repeat compatible class replacement for a brush entity.
4. In a fresh extracted package, verify maximized windowed launch, hover highlight off and sky overlay off. Enable both options and confirm the surfaces themselves remain visible.
5. Save As into another folder. Reopen Open/Save As and check the directory. Reload resources and check Compile/Launch variables still refer to the saved path.
6. With baseq3 unset, press Build and close setup using X; reopen setup and configure it. Check close buttons on Save changes, document errors and Replace Material.
7. Build with the bundled compiler; change stage selection and advanced arguments. Check streamed output, cancellation and a compiler error. Confirm a failed build retains the last successful BSP.
8. Press F10 into/out of the BSP; confirm selection, camera and Undo/Redo survive. Inspect scrolling/waving/animated materials with a stationary camera; move around reflective or billboard shaders to check camera response.
9. Check your custom q3map2 path still overrides the bundled one. Test paths containing spaces.

## Automated verification

Patch material/UV tests cover 10 assertions and exact MAP round-trip. Build tests cover 17 assertions, full BSP/VIS/LIGHT, LIGHT-only rebuild, error/cancellation retention, edit history and snapshot identity. The animation fixture compares two static-camera BSP images. Gesture constraints and a private copy of a 5,015-brush map are also checked; the original map is not modified.
