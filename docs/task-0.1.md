## Roadmap task 0.1 — action routing (0.5.0-alpha.1)

The editor now routes keyboard commands through a catalogue of 190 actions, including reserved future commands and mouse-gesture references. File/Edit/View/Run/Help menus use this catalogue. **Help → Action reference** lists implementation status; disabled entries do not imply implemented tools. Ctrl+Shift+Z and Ctrl+Y both redo. Text entry and popup dialogs suppress editor shortcuts; Escape remains available. Modifiers and held camera keys reset when plugin focus is lost or another map opens.

The current wheel-to-grid and WASD-without-RMB behavior remains unchanged. Numeric grid shortcuts, the new tool model and the Escape cascade belong to later roadmap tasks. The existing Smart/Move/Box/Clip controls remain in this build.

[All registered shortcuts](docs/shortcuts.md) are generated from the running engine's `ftebroom_actions_dump`. The  is retained unchanged. This release implements task 0.1 only; interactive acceptance is pending before task 0.2.

### Test this preview

1. Create a brush, press C, place cut points and apply with Enter.
2. Check Ctrl+Z, Ctrl+Y and Ctrl+Shift+Z; each should undo/redo the same operation.
3. Type `cwasdz` in the material filter and use Ctrl+Z there: no scene command should run.
4. Open a file confirmation or Action reference, press C/Ctrl+Z, then Escape: the map must stay unchanged and the dialog should close.
5. Hold W, leave editor focus, release W, return: movement must not remain stuck. Repeat with Alt and Shift; test your usual Windows scaling and keyboard layout.
6. In the scene press Q: the reserved camera action must leave the map unchanged. Unimplemented menu entries must be disabled.

Automated event tests do not replace these physical keyboard/focus checks. Use disposable maps.

---
