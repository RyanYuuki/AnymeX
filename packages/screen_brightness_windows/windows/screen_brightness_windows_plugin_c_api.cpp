#include "include/screen_brightness_windows/screen_brightness_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>

void ScreenBrightnessWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  auto* registrar_windows =
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  if (!registrar_windows) return;

  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar_windows->messenger(),
          "github.com/aaassseee/screen_brightness",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "getSystemScreenBrightness" ||
        call.method_name() == "getApplicationScreenBrightness") {
      result->Success(flutter::EncodableValue(1.0));
      return;
    }
    if (call.method_name() == "hasApplicationScreenBrightnessChanged" ||
        call.method_name() == "isAutoReset" ||
        call.method_name() == "isAnimate") {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    result->Success();
  });
}
