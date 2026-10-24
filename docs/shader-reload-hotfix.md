# Shader reload crash hotfix

Opening hotel02 after changing resource profiles could crash in
`Shader_LoadPermutation`. The Windows crash report resolves to the read of the
shader cvar metadata. `Shader_LoadGeneric` freed that metadata but retained its
size. Reloading a program without cvar declarations then read a null pointer.

The engine patch resets the size alongside its pointer. It changes neither map
data nor shader effects. Both platform build scripts automatically apply it.

Validation: a disposable engine test replaces the loaded grid GLSL with a version
without cvar declarations, then triggers shader reload. The old Windows engine
produces an access violation; patched Windows and Linux engines survive and exit.
The Linux test runs under Ubuntu/Xvfb, not a physical Arch/Wayland desktop.

Manual checks: open hotel02 in FTE Custom game, switch defaultwall sources and
reload resources several times, reopen the map, and check MAP/BSP rendering.

# Исправление вылета при перезагрузке шейдеров

Движок освобождал список параметров GLSL, сохраняя старый размер. Загрузка
варианта без параметров приводила к обращению по нулевому указателю. Исправлен
сброс размера; карта, ресурсы мода и эффекты шейдеров не меняются.

Проверка: открыть hotel02 в FTE Custom game, несколько раз изменить источник
defaultwall и перезагрузить ресурсы, повторно открыть карту и проверить MAP/BSP.
