import 'package:web/web.dart' as web;

String? getSessionValue(String key) => web.window.sessionStorage.getItem(key);

void setSessionValue(String key, String value) {
  web.window.sessionStorage.setItem(key, value);
}

void removeSessionValue(String key) {
  web.window.sessionStorage.removeItem(key);
}
