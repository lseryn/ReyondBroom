# Model import and skins

Drop a model from the operating system file manager into the editor's Mod file manager. A conversion window opens before any import is committed. Multiple dropped models are queued; closing the window skips the current model. The original file is never overwritten.

* Quake 1 selects Quake MDL with an embedded skin, using the active game's `gfx/palette.lmp`.
* Quake III selects MD3 with copied TGA textures.
* FTE Custom game offers the implemented exporters: MDL, MD3 and OBJ + MTL. The list is **not** every format that FTE can read. A model loader alone does not provide an exporter for that format.

MDL/MD2/MD3/IQM/MD5Mesh and other native FTE models use the engine's geometry extractor. `.md5` is treated as MD5Mesh. Half-Life MDL v10 uses the Half-Life renderer's bone evaluation; keep companion texture and animation files beside the original. Default bodygroups and the first skin are exported. Model events are never executed.

FBX, GLB, glTF and BLEND use an installed Blender executable, selected in the conversion window and remembered. Blender is a separate dependency, not bundled. SMD and DMX use bundled [Blender Source Tools](https://github.com/Artfunkel/BlenderSourceTools), pinned to revision `3d5fd9bf681547d86fa369715a0e8dd6013edcb7` (requires Blender 4.1 or newer). Source materials need accessible diffuse images; unresolved VMT/VTF dependencies must be prepared in Blender or supplied as PNG/TGA/JPEG. Missing textures fail conversion instead of silently producing an untextured model.

Blender runs in the background with factory startup settings and automatic file scripts disabled. It samples evaluated world-space geometry and bakes diffuse colour to one 512×512 texture per mesh object. One Blender unit becomes one map unit. There is no automatic centering, fit-to-box scaling or decimation. Use the first frame, frame count and sampling FPS controls to choose animation sampling. Native models use a sequence index; `-1` samples successive MDL/MD2 poses.

Confirm the displayed losses before conversion: skeletal rigs, tags, events and alternate skins are not retained as such; the chosen animation is baked. Transparency, normal maps and runtime shader effects cannot be reproduced by a Quake palette skin. MDL uses a padded 256-pixel tile per material and excludes fullbright palette entries. MDL positions have 8-bit precision per axis over the complete animation bounds. MD3 positions have 1/64-unit precision and must fit −512 to 511.984 units. An out-of-range model is rejected rather than silently resized. OBJ exports the first pose only. Existing output files are preserved.

Double-click a model to open Model Viewer. **Skin** changes its built-in skin. Matching external `.skin` files appear under **Material set (.skin)**. **Skin texture** displays the selected embedded Quake MDL skin as a flat image. Skin changes are previews and do not rewrite the model or alter entities on the map.

Validation includes transformed, animated BLEND/FBX/GLB fixtures, embedded-texture MDL round trips, portable MD3 texture paths, and a self-authored animated Half-Life v10 fixture. Arbitrary production assets still need inspection, particularly models with procedural materials, separate animation files, unusual UVs or importer-specific unit conventions.
