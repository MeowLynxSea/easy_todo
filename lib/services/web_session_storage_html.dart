import 'package:web/web.dart' as web;

String? getSessionValue(String key) {
  try {
    return web.window.sessionStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void setSessionValue(String key, String value) {
  try {
    web.window.sessionStorage.setItem(key, value);
  } catch (_) {}
}

void removeSessionValue(String key) {
  try {
    web.window.sessionStorage.removeItem(key);
  } catch (_) {}
}
