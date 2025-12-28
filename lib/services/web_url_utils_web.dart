import 'package:web/web.dart' as web;

Uri currentWebUrl() => Uri.parse(web.window.location.href);

void replaceWebUrl(Uri url) {
  web.window.history.replaceState(null, '', url.toString());
}

void navigateWebUrl(Uri url) {
  web.window.location.href = url.toString();
}
