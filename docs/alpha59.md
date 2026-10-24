# Alpha 59: custom editor GLSL file

In **Edit → Preferences → Game profile → Game / resources...**, choose **FTE Custom game**. Set **Editor defaultwall → Custom GLSL file**, then **Browse...**. The file dialog supports folder navigation, Up, a directly editable directory, Refresh, single-file selection and double-click confirmation. It shows `.glsl` files, including uppercase extensions. Cancel and the close button leave the previous selection intact.

Apply/load the profile resources to save the selected absolute path and activate the shader. Restarting the editor restores the selection. Existing profile settings remain compatible. Quake 1 and Quake 3 do not use this override.

The file is read without modifying it and staged in the editor's writable area as the existing defaultwall override. This is an FTE-compatible wall shader program, not an arbitrary GLSL program from another engine. Includes continue to resolve through mounted game resources; the file's sibling include files are not automatically imported. Missing/empty/non-text files, wrong extensions and files exceeding 1 MiB produce an error. Shader syntax or graphics-driver errors are reported by FTE in its console.

## Checks

1. Choose FTE Custom game and browse to a `.glsl` file in a directory with spaces/non-ASCII characters. Try Up, folder selection, Cancel, close and double-click confirmation.
2. Apply resources. Inspect the wall rendering; restart the editor and verify the file and mode remain selected.
3. Switch back to Current FTE default, reload resources, and verify the override is disabled.
4. Switch to Quake 1/3; the custom-file control must be absent and the override disabled.
5. Select a missing or empty file and check the error. The source file must remain unchanged.
6. If the shader uses includes, verify they are available through the configured game resource paths.

Windows and Arch Linux/Xvfb tests exercise Unicode paths, profile persistence across two process launches, shader staging/loading, invalid-file handling and Quake 1/3 isolation. Real Wayland desktop behavior is not covered by Xvfb.
