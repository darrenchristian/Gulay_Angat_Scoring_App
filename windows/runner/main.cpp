#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <cstdint>
#include <cstring>
#include <string>

#include "flutter_window.h"
#include "utils.h"

// Compatibility shims for newer MSVC STL vectorized intrinsics referenced by
// precompiled Firebase C++ SDK static libraries when linking with older MSVC toolsets.
extern "C" {
int _Avx2WmemEnabled = 0;

const void* __cdecl __std_search_1(const void* first1, const void* last1,
                                   const void* first2, size_t count2) {
  const auto* p1 = static_cast<const uint8_t*>(first1);
  const auto* end1 = static_cast<const uint8_t*>(last1);
  const auto* p2 = static_cast<const uint8_t*>(first2);
  if (count2 == 0) return first1;
  const size_t len1 = static_cast<size_t>(end1 - p1);
  if (len1 < count2) return last1;
  for (size_t i = 0; i <= len1 - count2; ++i) {
    if (std::memcmp(p1 + i, p2, count2) == 0) {
      return p1 + i;
    }
  }
  return last1;
}

const void* __cdecl __std_find_end_1(const void* first1, const void* last1,
                                     const void* first2, size_t count2) {
  const auto* p1 = static_cast<const uint8_t*>(first1);
  const auto* end1 = static_cast<const uint8_t*>(last1);
  const auto* p2 = static_cast<const uint8_t*>(first2);
  if (count2 == 0) return last1;
  const size_t len1 = static_cast<size_t>(end1 - p1);
  if (len1 < count2) return last1;
  for (size_t i = len1 - count2 + 1; i > 0; --i) {
    if (std::memcmp(p1 + (i - 1), p2, count2) == 0) {
      return p1 + (i - 1);
    }
  }
  return last1;
}

void* __cdecl __std_remove_8(void* first, void* last, uint64_t val) {
  auto* read_ptr = static_cast<uint64_t*>(first);
  auto* end_ptr = static_cast<uint64_t*>(last);
  auto* write_ptr = read_ptr;
  for (; read_ptr != end_ptr; ++read_ptr) {
    if (*read_ptr != val) {
      *write_ptr++ = *read_ptr;
    }
  }
  return write_ptr;
}

size_t __cdecl __std_find_first_of_trivial_pos_1(const void* haystack,
                                                 size_t haystack_length,
                                                 const void* needle,
                                                 size_t needle_length) {
  const auto* h = static_cast<const uint8_t*>(haystack);
  const auto* n = static_cast<const uint8_t*>(needle);
  for (size_t i = 0; i < haystack_length; ++i) {
    for (size_t j = 0; j < needle_length; ++j) {
      if (h[i] == n[j]) return i;
    }
  }
  return static_cast<size_t>(-1);
}

size_t __cdecl __std_find_last_of_trivial_pos_1(const void* haystack,
                                                size_t haystack_length,
                                                const void* needle,
                                                size_t needle_length) {
  const auto* h = static_cast<const uint8_t*>(haystack);
  const auto* n = static_cast<const uint8_t*>(needle);
  for (size_t i = haystack_length; i > 0; --i) {
    for (size_t j = 0; j < needle_length; ++j) {
      if (h[i - 1] == n[j]) return i - 1;
    }
  }
  return static_cast<size_t>(-1);
}
}  // extern "C"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 800);
  std::wstring window_title = L"GulayAngat ScoreSync";

  for (const auto& arg : command_line_arguments) {
    if (arg == "--instance=1") {
      origin = Win32Window::Point(10, 10);
      size = Win32Window::Size(960, 840);
      window_title = L"GulayAngat ScoreSync - Instance 1 (Admin)";
    } else if (arg == "--instance=2") {
      origin = Win32Window::Point(980, 10);
      size = Win32Window::Size(600, 500);
      window_title = L"GulayAngat ScoreSync - Instance 2 (Judge 1)";
    } else if (arg == "--instance=3") {
      origin = Win32Window::Point(980, 530);
      size = Win32Window::Size(600, 500);
      window_title = L"GulayAngat ScoreSync - Instance 3 (Judge 2)";
    }
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  if (!window.Create(window_title, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
