import 'package:flutter/material.dart';
import 'package:elimupepe/features/settings/webview_content_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String _termsUrl =
      'https://loho-stack.github.io/app-policies/';

  @override
  Widget build(BuildContext context) {
    return const WebViewContentScreen(
      title: 'Terms & Conditions',
      url: _termsUrl,
    );
  }
}
