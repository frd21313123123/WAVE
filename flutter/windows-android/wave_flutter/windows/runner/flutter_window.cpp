#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cwctype>
#include <filesystem>
#include <optional>
#include <shellapi.h>

#include "flutter/generated_plugin_registrant.h"

namespace {
constexpr char kUpdaterChannelName[] = "com.wave.messenger/updater";
constexpr char kInstallDownloadedUpdateMethod[] = "installDownloadedUpdate";

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  const int required_size = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(),
      static_cast<int>(value.size()), nullptr, 0);
  if (required_size <= 0) {
    return std::wstring();
  }

  std::wstring output(required_size, L'\0');
  const int converted = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(),
      static_cast<int>(value.size()), output.data(), required_size);
  if (converted <= 0) {
    return std::wstring();
  }

  return output;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int required_size = WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  if (required_size <= 0) {
    return std::string();
  }

  std::string output(required_size, '\0');
  const int converted = WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), output.data(),
      required_size, nullptr, nullptr);
  if (converted <= 0) {
    return std::string();
  }

  return output;
}

std::wstring ToLower(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t ch) { return std::towlower(ch); });
  return value;
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterUpdaterChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  updater_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterUpdaterChannel() {
  updater_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), kUpdaterChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  updater_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != kInstallDownloadedUpdateMethod) {
          result->NotImplemented();
          return;
        }

        const std::optional<std::wstring> update_path =
            ExtractUpdatePath(call.arguments());
        if (!update_path || update_path->empty()) {
          result->Error("invalid_args",
                        "Expected a non-empty update file path.");
          return;
        }

        std::wstring error_message;
        if (!LaunchUpdateFile(*update_path, &error_message)) {
          result->Error("launch_failed", WideToUtf8(error_message));
          return;
        }

        const bool should_close = RequiresAppShutdownForUpdate(*update_path);
        flutter::EncodableMap payload;
        payload[flutter::EncodableValue("launched")] =
            flutter::EncodableValue(true);
        payload[flutter::EncodableValue("closeRequested")] =
            flutter::EncodableValue(should_close);
        result->Success(flutter::EncodableValue(std::move(payload)));

        if (should_close) {
          PostMessage(GetHandle(), WM_CLOSE, 0, 0);
        }
      });
}

bool FlutterWindow::LaunchUpdateFile(const std::wstring& file_path,
                                     std::wstring* error_message) {
  namespace fs = std::filesystem;

  std::error_code error_code;
  const fs::path requested_path(file_path);
  const fs::path resolved_path = fs::absolute(requested_path, error_code);
  if (error_code || !fs::exists(resolved_path)) {
    if (error_message != nullptr) {
      *error_message = L"Downloaded update file was not found.";
    }
    return false;
  }

  const std::wstring working_directory =
      resolved_path.has_parent_path() ? resolved_path.parent_path().wstring()
                                      : std::wstring();
  const HINSTANCE launch_result = ShellExecuteW(
      nullptr, L"open", resolved_path.c_str(), nullptr,
      working_directory.empty() ? nullptr : working_directory.c_str(),
      SW_SHOWNORMAL);
  if (reinterpret_cast<INT_PTR>(launch_result) <= 32) {
    if (error_message != nullptr) {
      *error_message = L"Windows could not launch the downloaded update file.";
    }
    return false;
  }

  return true;
}

std::optional<std::wstring> FlutterWindow::ExtractUpdatePath(
    const flutter::EncodableValue* arguments) {
  if (arguments == nullptr) {
    return std::nullopt;
  }

  if (const auto* raw_path = std::get_if<std::string>(arguments)) {
    const std::wstring decoded = Utf8ToWide(*raw_path);
    return decoded.empty() ? std::nullopt
                           : std::optional<std::wstring>(decoded);
  }

  const auto* map = std::get_if<flutter::EncodableMap>(arguments);
  if (map == nullptr) {
    return std::nullopt;
  }

  const auto iterator = map->find(flutter::EncodableValue("path"));
  if (iterator == map->end()) {
    return std::nullopt;
  }

  const auto* raw_path = std::get_if<std::string>(&iterator->second);
  if (raw_path == nullptr) {
    return std::nullopt;
  }

  const std::wstring decoded = Utf8ToWide(*raw_path);
  return decoded.empty() ? std::nullopt : std::optional<std::wstring>(decoded);
}

bool FlutterWindow::RequiresAppShutdownForUpdate(const std::wstring& file_path) {
  const std::wstring extension =
      ToLower(std::filesystem::path(file_path).extension().wstring());
  return extension == L".exe" || extension == L".msi" ||
         extension == L".msix" || extension == L".msixbundle" ||
         extension == L".appinstaller";
}
