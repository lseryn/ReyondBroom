// SPDX-License-Identifier: GPL-2.0-or-later
static bool clipboardTestActive;
static std::string clipboardTestText;
static std::string clipboardPending;
static bool clipboardPendingOriginal;
static bool clipboardOversize;
static void clipboardReceived(void* context, const char* text)
{
  if (!text || !*text)
    return;
  if (std::strlen(text) > 16 * 1024 * 1024)
  {
    clipboardOversize = true;
    return;
  }
  // Async platform callbacks must not call FTE APIs without a plugin context.
  clipboardPending = text;
  clipboardPendingOriginal = context != nullptr;
}
static void clipboardPump()
{
  if (clipboardOversize)
  {
    clipboardOversize = false;
    cvars->SetString("ftebroom_selection_status", "Clipboard exceeds 16 MiB");
  }
  if (clipboardPending.empty())
    return;
  std::string text = std::move(clipboardPending);
  clipboardPending.clear();
  qhandle_t handle;
  if (files->Open("data/clipboard-in.map", &handle, 2) < 0)
    return;
  files->Write(handle, text.data(), static_cast<int>(text.size()));
  files->Close(handle);
  command(
    clipboardPendingOriginal ? "ftebroom_paste_file 1\n" : "ftebroom_paste_file 0\n");
}
static void clipboardAction(const std::string& name)
{
  if (name == "copy" || name == "cut")
    command(name == "cut" ? "ftebroom_copy_file 1\n" : "ftebroom_copy_file 0\n");
  else if (clipboardTestActive)
    clipboardReceived(
      name == "pasteoriginal" ? reinterpret_cast<void*>(1) : nullptr,
      clipboardTestText.c_str());
  else if (input->ClipboardGet)
    input->ClipboardGet(
      0,
      clipboardReceived,
      name == "pasteoriginal" ? reinterpret_cast<void*>(1) : nullptr);
}
static void clipboardReady()
{
  if (!input->ClipboardSet)
    return;
  qhandle_t handle;
  const auto length = files->Open("data/clipboard-out.map", &handle, 1);
  if (length < 0)
    return;
  if (length == 0 || length > 16 * 1024 * 1024)
  {
    files->Close(handle);
    return;
  }
  std::string text(static_cast<size_t>(length), '\0');
  const auto read = files->Read(handle, text.data(), static_cast<int>(length));
  files->Close(handle);
  if (read != length)
    return;
  if (clipboardTestActive)
    clipboardTestText = text;
  else
    input->ClipboardSet(0, text.c_str());
  char cut[16];
  commands->Argv(1, cut, sizeof cut);
  if (std::string(cut) == "1")
    command("ftebroom_delete\n");
}

static void clipboardTestCommand()
{
  if (!cvars->GetFloat("ftebroom_skip_setup"))
    return;
  char operation[32];
  commands->Argv(1, operation, sizeof operation);
  if (std::string(operation) == "begin")
  {
    // Exercise the native/QC bridge without touching the user's OS clipboard.
    clipboardTestActive = true;
    command("ftebroom_copy_file 0\n");
  }
  else if (std::string(operation) == "restore")
  {
    clipboardTestText.clear();
    clipboardTestActive = false;
  }
}
