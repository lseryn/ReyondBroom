# FTEBroom alpha 43

## Files and resources

PK3 files now open as folders with the same browse, extract/copy, import, rename and text-edit operations as PAK. ZIP32 stored/deflated entries are supported. Encrypted, split and ZIP64 archives are rejected. Unchanged compressed payloads are preserved; ZIP extra metadata is not.

Right-click **Delete (keep backup)** to delete a file or folder. Loose items move into a sibling `.ftebroom-trash`; archive edits preserve a timestamped `.bak`. These operations are separate from map Undo. Use **Reload engine resources** after editing mounted assets to reopen archive handles. This does not compile game code.

Double-click `.shader`, `.c`, `.qc`, `.txt`, `.cfg`, `.glsl`, `.json`, `.md` and other recognized text files. MAP keeps its map-opening action. Text files up to 1 MiB are supported, with Save/Discard/Cancel on dirty close/switch and a backup on save. External changes since opening prevent overwrite.

Image decoding runs on one background worker; GPU uploads remain on the render thread. The thumbnail cache is bounded to 256 entries. Offscreen hierarchy rows skip widget rendering. Fixed row spacing and a stable scrollbar prevent bottom-row jitter.

## Editor defaultwall

In **FTE Custom game**, choose **Editor defaultwall**: current FTE behavior, map source folder, mod folder, or **Neutral studio (Unity-like)**. Apply/reload the profile resources. Source/mod choices require `glsl/defaultwall.glsl`, loose or in a top-level PAK/PK3. Its custom includes still resolve through the mounted resource search path.

Studio is an original diffuse/specular preview approximation, not Unity code or full PBR. Explicit custom shader programs retain their behavior. Mod/source files are not rewritten. Quake 1/3 do not enable this override.

## Array and Perforate

**Edit > Array...** creates linear, radial or seeded random copies. Count means additional copies. Radial mode optionally rotates them. Originals remain, copies are selected, and Apply is one Undo. Limits: 64 additional copies and 512 resulting objects.

Perforate constructs prisms directly and rejects **holes x sides > 128** before mutation. Impossible placement or degenerate thin fragments cancel the operation. Some dense/high-sided configurations still cannot be constructed. This is not unlimited-hole support.

## Manual checks on both platforms

1. Browse a PK3, view images/models/text, extract/import, rename and delete entries; reopen with an external ZIP reader. Check backups and Reload engine resources.
2. Delete a loose file/folder and recover it from `.ftebroom-trash`.
3. Edit/save/reopen text. Test Save, Discard and Cancel on dirty close/switch; externally modify an open file and confirm overwrite is refused.
4. Browse a large image folder, scroll to the bottom, resize thumbnails. They should load progressively without row jitter.
5. Test every defaultwall choice in FTE Custom, then switch to Quake 1/3. Test a missing shader and its error message.
6. Test Array with brushes/entities: count, position, materials, seed, Undo/Redo and save/reopen.
7. Test ordinary holes and keep/remove plugs, then excessive count/sides and impossible sizes. Rejection must preserve the original brush and a usable editor.
8. Recheck Linux Wayland clipboard, cursor and external WAD drop, Windows file dialogs, and map compilation on both platforms.

Full ReyondBroom parity is not claimed. Remaining tools and platform differences are recorded in [the parity ledger](reyond-parity.md).
