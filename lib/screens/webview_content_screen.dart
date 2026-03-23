import 'package:flutter/material.dart';
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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
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
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
