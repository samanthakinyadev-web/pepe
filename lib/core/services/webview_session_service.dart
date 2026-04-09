import 'package:webview_flutter/webview_flutter.dart';

class WebViewSessionService {
  WebViewSessionService._();

  static final WebViewCookieManager _cookieManager = WebViewCookieManager();

  static Future<void> clear() async {
    try {
      await _cookieManager.clearCookies();
    } catch (_) {
      // Ignore WebView cleanup failures so logout still completes.
    }
  }
}
