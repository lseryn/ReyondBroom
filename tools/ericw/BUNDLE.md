# Pinned Quake compiler bundle

Run `scripts/fetch-ericw.ps1` to fetch and checksum-verify the unmodified ericw-tools 0.18.1 Windows x64 release and corresponding source. `scripts/build-windows.ps1` runs this automatically. The complete release package includes QBSP, VIS, LIGHT, dependencies, GPL text, upstream dependency notices and the source ZIP. Paths remain user-editable.

`PIN.json` records archive and binary hashes. Generated binaries, source archive and upstream HTML documentation are excluded from Git to avoid duplicating the distributed package. Packaging requires the local bundle; it does not download anything at editor runtime.

The tools are independent executables under their upstream GPL-3.0 license. Embree and TBB retain their release notices; see `LICENSE-embree.txt`, `gpl_v3.txt` and upstream `README.md` after fetching. FTEBroom does not link the compiler libraries into its plugin.
