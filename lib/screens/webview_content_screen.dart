import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContentScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewContentScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewContentScreen> createState() => _WebViewContentScreenState();
}

class _WebViewContentScreenState extends State<WebViewContentScreen> {
  static const String _siteHost = 'elimupepe.loholearning.co.ke';

  late final WebViewController _controller;
  late String _pageTitle;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (url) async {
            await _applyReadabilityFix();
            await _syncPageTitle();
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );
    _loadUrl(widget.url);
  }

  @override
  void didUpdateWidget(covariant WebViewContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _pageTitle = widget.title;
      _loadUrl(widget.url);
    } else if (oldWidget.title != widget.title &&
        _pageTitle == oldWidget.title) {
      _pageTitle = widget.title;
    }
  }

  Future<void> _loadUrl(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    final headers = await _buildHeadersForUrl(uri);
    await _controller.loadRequest(uri, headers: headers);
  }

  Future<Map<String, String>> _buildHeadersForUrl(Uri uri) async {
    if (uri.host.toLowerCase() != _siteHost) {
      return const {};
    }

    final token =
        await _secureStorage.read(key: 'passport_token') ??
        await _secureStorage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      return const {};
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json, text/html, */*',
    };
  }

  Future<void> _syncPageTitle() async {
    try {
      final title = await _controller.getTitle();
      if (!mounted || title == null || title.trim().isEmpty) {
        return;
      }

      setState(() {
        _pageTitle = title.trim();
      });
    } catch (_) {
      // Keep the original title if the webview cannot expose one.
    }
  }

  Future<void> _applyReadabilityFix() async {
    const script = '''
      (() => {
        const isNearWhite = (rgb) => rgb && rgb[0] >= 235 && rgb[1] >= 235 && rgb[2] >= 235;
        const parseColor = (value) => {
          if (!value) return null;
          const match = value.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/i);
          if (!match) return null;
          return [Number(match[1]), Number(match[2]), Number(match[3])];
        };
        const effectiveBackground = (element) => {
          let current = element;
          while (current) {
            const style = window.getComputedStyle(current);
            const color = parseColor(style.backgroundColor);
            if (color && style.backgroundColor !== 'rgba(0, 0, 0, 0)' && style.backgroundColor !== 'transparent') {
              return color;
            }
            current = current.parentElement;
          }
          return [255, 255, 255];
        };

        const elements = [document.body, ...document.querySelectorAll('body *')].filter(Boolean);
        for (const element of elements) {
          const style = window.getComputedStyle(element);
          const textColor = parseColor(style.color);
          const fillColor = parseColor(style.webkitTextFillColor);
          const background = effectiveBackground(element);
          const whiteText = isNearWhite(textColor) || isNearWhite(fillColor);

          if (whiteText && isNearWhite(background)) {
            element.style.setProperty('color', '#1F2937', 'important');
            element.style.setProperty('-webkit-text-fill-color', '#1F2937', 'important');
          }
        }
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // Ignore script injection failures for pages that block custom JS.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen,
        title: Text(_pageTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.lightGreen),
            ),
        ],
      ),
    );
  }
}
