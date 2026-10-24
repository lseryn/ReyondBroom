# Alpha 58: existing-tool maintenance

This release concentrates on existing workflows. New preview systems, model export formats, game profiles and Linux embedded mod rendering are outside this maintenance scope.

## Crash fix

Fixed an out-of-bounds face read when geometry handles were rebuilt in ordinary object mode after Settle Apply. The shared rebuild function now clears stale handles and returns unless a vertex/edge/face/control-point tool is active. The existing brush-on-patch Settle regression reproduced the crash on both Windows and Linux before the fix.

## Texture-folder WAD fixes

The existing Quake 1 texture-folder importer now retains dimensions divisible by 16, up to 4096 per axis. Other dimensions round up to a multiple of 16. Source images remain limited to 16 million pixels. PNG/JPEG/TGA/BMP decoding uses the same palette conversion on Windows and Linux.

Opaque textures can use all 256 palette entries, including fullbright colors. Names starting with `{` reserve index 255 for transparency: alpha below 128 becomes transparent, while opaque pixels use entries 0–254. Mipmap generation preserves the transparency policy. Generated editor textures also retain cutout alpha. This does not add a new lighting preview or change shader behavior in the user's game.

Exact RGB lookup caching speeds repeated colors without approximating palette matching. Zero-sized or oversized WAD entries are rejected. Folder compilation remains cancellable; the previous WAD backup and compiler staging remain in place. The separate single-image import dialog retains its existing size/palette policy.

## Verification and limits

Standalone tests cover palette indices, mipmaps, cutout alpha, image dimensions, cancellation and invalid input. Native Windows and Arch Linux/Xvfb tests import source images through the actual decoders, rebuild the WAD, stage it for qbsp and compare the resulting BSP texture pixels with the WAD. Includes a 1024×16 fullbright fixture and a masked texture.

Existing-tool regression coverage includes Bevel, Symmetry, Spin, Bend, Array, Rock/Sculpt, Inset/Subdivision/Settle, Polygon Cut/Spawn, Spawn Master, Unity export and keyboard/text-focus handling. These tests do not establish complete interaction parity or arbitrary-mod compatibility. Real Unity Editor and a real Wayland desktop are not available in this test environment.

Exact Bevel contact clamp, arbitrary symmetry counterpart discovery, specialized polygon topology and broader live-apply interaction remain tracked in [the comparison ledger](reyond-parity.md). They are not reported as completed by this release.

## User checks

1. Rebuild an existing texture folder; verify names and material assignments remain usable, and the previous WAD backup exists.
2. Import a 1024×16 image and an odd-sized image; inspect dimensions. Test PNG, JPEG and TGA.
3. Import a transparent image whose filename starts with `{`; inspect the cutout, apply it to a brush and build a disposable map. Verify the game supports the masked material convention.
4. Test a fullbright-color texture with the selected game's palette in the compiled BSP. Check ordinary materials are still acceptable with the full palette policy.
5. Cancel a large folder rebuild; verify the last completed WAD remains usable.
6. Run Settle above a patch, Apply, Undo and Redo in ordinary object mode; then switch to vertex/edge/face editing. No crash or stale handles should appear. On a copy of a working map, preview/apply/cancel Bevel, Symmetry, Spin/Bend, Array and Rock/Sculpt. Undo/Redo and save/reopen.
7. If using Unity, validate the exported prefab and rendering in the actual Editor. On Wayland, test cursor boundaries, clipboard and external file drops; automated Xvfb tests cannot replace this check.
