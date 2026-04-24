import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  factory AnalyticsService() => instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  FirebaseAnalytics? get analytics {
    if (!_isSupportedPlatform) return null;
    try {
      return _analytics ??= FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  NavigatorObserver? get navigatorObserver {
    final analyticsInstance = analytics;
    if (analyticsInstance == null) return null;
    return _observer ??= FirebaseAnalyticsObserver(analytics: analyticsInstance);
  }

  Future<void> setCollectionEnabled(bool enabled) async {
    final analyticsInstance = analytics;
    if (analyticsInstance == null) return;
    try {
      await analyticsInstance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  Future<void> logLogin({required String method}) async {
    final analyticsInstance = analytics;
    if (analyticsInstance == null) return;
    try {
      await analyticsInstance.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    final analyticsInstance = analytics;
    if (analyticsInstance == null) return;
    try {
      await analyticsInstance.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }
}
