//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

<<<<<<< HEAD
=======
#include <app_links/app_links_plugin_c_api.h>
>>>>>>> 8b32b3faebf56148495e42cbb9f47ffda8173a99
#include <rive_common/rive_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
<<<<<<< HEAD
=======
  AppLinksPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AppLinksPluginCApi"));
>>>>>>> 8b32b3faebf56148495e42cbb9f47ffda8173a99
  RivePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RivePlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
