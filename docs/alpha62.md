# Alpha.62: automatic model conversion runtime

The first **Bake and convert** operation for FBX, GLB/glTF, BLEND, SMD or DMX automatically downloads portable Blender 5.0.0 from `download.blender.org`. The conversion window displays downloading, verification and extraction progress. The selected conversion resumes automatically after installation. Later conversions reuse the cached runtime, including offline. No Blender installation or executable-path configuration is needed.

Windows uses its built-in PowerShell. Linux uses Python 3 with the `tarfile` data extraction filter (Python 3.12+ recommended) and Blender's normal system libraries. Allow approximately 400 MB of download and 4 GiB of free disk space. SHA-256 is pinned separately for each platform. Partial downloads are not installed; errors are displayed in the conversion window and **Bake and convert** retries. The editor updater preserves the `downloads` cache.

Native FTE formats do not trigger this download. Export formats and conversion losses are unchanged: Quake MDL, MD3, and static OBJ+MTL. See [model import](model-import64.md).

## Checks

1. In a fresh disposable installation, drop a GLB or FBX into Mod file manager, acknowledge format losses and click **Bake and convert**. Check progress and automatic conversion without choosing a Blender path.
2. Check the resulting model's texture, size, position and animation.
3. Convert another model after disconnecting the network. The cached component should be reused.
4. Try the first download without network access. Check the error, reconnect and retry.
5. Native MDL/MD3 conversion should continue without downloading Blender.

## Proposed Source project import (not implemented)

A future **Import Source project** flow could take a primary QC file and an ordered list of model, animation and material directories. Parse an allowlisted subset of QC directives as data; never execute commands. Resolve includes and file references through the selected roots, detect cycles, and show unresolved or ambiguous dependencies before building.

The user would select bodygroups, skin variants, sequences and LOD. Check skeleton compatibility, apply the declared transforms once, bake the selected animations, and combine meshes into one Quake MDL with a palette atlas. Model size and origin must remain explicit. A sidecar report would record sequence frame ranges and losses because Quake MDL does not retain Source QC semantics, events, physics or arbitrary bodygroups. Source VMT/VTF decoding and a real QC dependency resolver are additional work; dropping several unrelated folders is not yet a supported assembly workflow.
