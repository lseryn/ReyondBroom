# Alpha 55: Russian keyboard shortcuts

X11 now recognizes standard Russian ЙЦУКЕН letter positions for editor shortcuts. Windows and Wayland already use physical key codes. The X11 fallback handles legacy and Unicode keysyms, uppercase and lowercase; it does not replace Unicode characters delivered to text fields. Custom keyboard layouts are not remapped by this fallback.

## Checks

1. Switch between English and Russian layouts. Press C to toggle Clip, V for vertices and other configured tool shortcuts. Check modifiers and camera movement.
2. Type Russian text in material/entity searches and the text editor. Typing should not activate tools or move the camera.
3. Repeat after changing window focus, opening a popup and switching between 2D/3D views.
4. On Arch Linux, check both X11 and your normal Wayland session. Real Wayland interaction has not been exercised in the automated environment.

The regression compiles the actual patched X11 mapping and checks 132 letter/keysyms plus unrelated-key isolation. Engine integration checks the C shortcut with Cyrillic text and the text-input guard on Windows and Arch Linux under Xvfb. Existing engine crash regression tests also pass. This release continues the parity work; see the [remaining scope](reyond-parity.md).
