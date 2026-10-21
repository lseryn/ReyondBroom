// SPDX-License-Identifier: GPL-2.0-or-later
// Parse external diagnostic files before replacing the current overlay.
static int traceRequest, fileBrowserTrace;
static std::filesystem::path tracePaths[2];
static bool traceChoose(int kind, const std::filesystem::path& path)
{
  try
  {
    std::ifstream input(path);
    if (!input || std::filesystem::file_size(path) > 32 * 1024 * 1024)
      throw std::runtime_error("Cannot read diagnostic file (maximum size: 32 MiB).");
    std::ostringstream result;
    result.precision(9);
    auto point = [&]() {
      double x, y, z;
      if (!(input >> x >> y >> z) || !std::isfinite(x) || !std::isfinite(y)
          || !std::isfinite(z) || std::max({std::abs(x),std::abs(y),std::abs(z)}) > 1e7)
        throw std::runtime_error("Invalid diagnostic point.");
      result << x << ' ' << y << ' ' << z << '\n';
    };
    if (kind == 1)
    {
      int count = 0;
      while (input >> std::ws && input.peek() != EOF)
      {
        if (++count > 262144) throw std::runtime_error("Too many leak points.");
        point();
      }
      if (!count) throw std::runtime_error("The point file is empty.");
    }
    else
    {
      std::string magic;
      int leaves, portals;
      if (!(input >> magic >> leaves >> portals) || magic != "PRT1" || leaves < 0
          || portals < 0 || portals > 262144)
        throw std::runtime_error("Expected a PRT1 portal file.");
      int total = 0;
      for (int i = 0; i < portals; ++i)
      {
        int count, a, b;
        if (!(input >> count >> a >> b) || count < 3 || count > 1024
            || (total += count) > 262144)
          throw std::runtime_error("Invalid portal polygon.");
        result << count << '\n';
        for (int v = 0; v < count; ++v)
        {
          char delimiter;
          if (!(input >> delimiter) || delimiter != '(')
            throw std::runtime_error("Expected portal vertex.");
          point();
          if (!(input >> delimiter) || delimiter != ')')
            throw std::runtime_error("Expected closing portal vertex delimiter.");
        }
      }
    }
    qhandle_t output;
    if(files->Open(kind == 1 ? "data/leak.txt" : "data/portals.txt",&output,2)<0)
      throw std::runtime_error("Cannot stage diagnostic file.");
    auto data=result.str();files->Write(output,data.data(),data.size());files->Close(output);
    tracePaths[kind-1] = path;
    action(kind == 1 ? "ftebroom_trace loadpoints\n" : "ftebroom_trace loadportals\n");
    return true;
  }
  catch (const std::exception& error) { documentError = error.what(); return false; }
}
static void traceAutoLoad()
{
  action("ftebroom_trace unloadpoints\nftebroom_trace unloadportals\n");
  tracePaths[0].clear(); tracePaths[1].clear();
  if (documentFile.empty()) return;
  auto path = documentFile; path.replace_extension(".lin");
  std::error_code error;
  auto modified = std::filesystem::last_write_time(path, error);
  if (error) return;
  auto mapModified = std::filesystem::last_write_time(documentFile, error);
  if (!error && modified > mapModified) traceChoose(1, path);
}
static void testTraceFiles()
{
  if (!cvars->GetFloat("ftebroom_skip_setup")) return;
  auto path = documentPath("data/trace-test.lin");
  std::ofstream(path) << "0 0 64\n16 0 64\n32 16 64\n48 32 64\n64 32 80\n";
  core->Print(traceChoose(1,path) ? "FTEBROOM_TRACE_PASS native_points\n" : "FTEBROOM_TRACE_FAIL native_points\n");
  path = documentPath("data/trace-test.prt");
  std::ofstream(path) << "PRT1\n2\n1\n4 0 1 (0 0 64) (64 0 64) (64 64 64) (0 64 64)\n";
  core->Print(traceChoose(2,path) ? "FTEBROOM_TRACE_PASS native_portals\n" : "FTEBROOM_TRACE_FAIL native_portals\n");
  path = documentPath("data/invalid.prt");
  std::ofstream(path) << "PRT1\n2\n1\n2000000000 0 1\n";
  core->Print(!traceChoose(2,path) ? "FTEBROOM_TRACE_PASS rejects_invalid\n" : "FTEBROOM_TRACE_FAIL rejects_invalid\n");
  documentError.clear();
}
