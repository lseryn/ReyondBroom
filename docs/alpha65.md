# Alpha 65 — workspace and renderer fixes

## Tools panel

Compile, Setup compile, Show BSP and Preview mod follow the tool buttons, aligned to the left and matching their height. Icons and labels are vertically centered. Controls wrap when the available width is exhausted. Preview mod is shown for profiles that support it.

Sculpt, Bezier Bend, Polygon Cut, Polygon Spawn, Spin and Rotate Grid start collapsed behind an arrow. In a horizontal panel the arrow expands the group to the right; in a vertical panel it expands downward. Collapsing the group does not deactivate the current tool. Existing menu commands and shortcuts remain available.

Dock Tools on either side to stack its options vertically. Shape, Shape settings, Replace selection and movement fields fit the panel width. Other tool inputs show their labels above their fields in a side dock.

The **Shape / move** button expands brush creation and movement settings; this block starts collapsed too. Compile uses a hammer icon, Setup compile uses sliders, Show BSP uses a cube, and Preview mod uses a play symbol. All four retain translated text labels.

## Face hover and preview

- Shift hover draws the perimeter of the hovered brush face after the scene, without triangulation diagonals. Polygon lookup is cached while the pointer, camera and geometry remain unchanged.
- Compiling an unsaved map displays a prominent message at the top of the viewport.
- On Windows, mod preview starts hidden and shows a loading indicator until its renderer reports readiness. The child runtime no longer captures or warps the OS mouse; editor input is forwarded through a bounded command pipeline.
- Embedded mod preview remains Windows-only. Linux retains its existing external mod launch workflow.

Large-map face caches now reuse packed geometry buffers instead of allocating four heap blocks for every face. This reduces heap fragmentation during cache rebuilds without changing the rendered geometry.

## UV and MSAA

The mouse wheel over the UV canvas zooms the texture without scrolling its inspector. Modern Dark gives material and UV fields visible borders and distinct backgrounds.

Applying MSAA rebuilds the ImGui font atlas and invalidates GPU image caches. Editable MAP geometry, entities, selection and Undo/Redo are preserved across the renderer restart. For FTE Engine terrain or embedded mod preview, save the setting and restart the application instead; live renderer restart is disabled in those modes.

## Verification checklist

- Expand and collapse the extra tools in a top dock and a side dock; select each tool.
- Resize Tools until controls wrap. Check Shape settings, movement offsets and selected-tool parameters in left and right docks.
- Confirm Compile controls follow the icons without a centered gap.
- Zoom the UV canvas and scroll the inspector outside the canvas. Check field visibility in Modern Dark.
- Make an unsaved brush edit, Apply MSAA, then Undo/Redo; confirm the map and interface remain intact.

- Hold Shift over different visible cube faces: each has one yellow perimeter and no diagonal.
- Try Compile on an unsaved map, then save and compile normally.
- On Windows, start Preview mod, test free-camera motion and Play mod, open Escape controls, and return to editing. Check mouse smoothness on your mod and hardware.

Validated with Windows and Linux UI/UV runs; Windows gesture and MAP round-trip tests; and an embedded mod fixture test. The hotel02 round-trip retained 2,394 brushes and two patches, with the original file unchanged. This does not replace a visual check of every mod or graphics driver.
