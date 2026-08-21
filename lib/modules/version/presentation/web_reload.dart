import 'web_reload_stub.dart'
    if (dart.library.js_util) 'web_reload_web.dart'
    if (dart.library.html) 'web_reload_web.dart' as impl;

void reloadWeb() {
  impl.reloadWebImpl();
}
