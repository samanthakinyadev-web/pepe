import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class ErrorFeedback {
  static ErrorVisual visualFor(Object? error) {
    if (isSecureAccessError(error)) {
      return const ErrorVisual(
        label: 'Secure access',
        icon: Icons.lock_rounded,
        gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        accent: Color(0xFF1B5E20),
      );
    }

    if (isServerError(error)) {
      return const ErrorVisual(
        label: 'Server issue',
        icon: Icons.dns_rounded,
        gradient: [Color(0xFFE65100), Color(0xFFFF9800)],
        accent: Color(0xFFBF360C),
      );
    }

    if (isNetworkError(error)) {
      return const ErrorVisual(
        label: 'Connection issue',
        icon: Icons.wifi_off_rounded,
        gradient: [Color(0xFF1565C0), Color(0xFF4FC3F7)],
        accent: Color(0xFF0D47A1),
      );
    }

    return const ErrorVisual(
      label: 'Action required',
      icon: Icons.error_outline_rounded,
      gradient: [Color(0xFF2E7D32), Color(0xFF43A047)],
      accent: Color(0xFF1B5E20),
    );
  }

  static bool isNetworkError(Object? error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.badCertificate:
          return true;
        case DioExceptionType.badResponse:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          break;
      }

      final statusCode = error.response?.statusCode;
      return statusCode == null || statusCode == 0 || statusCode >= 500;
    }

    final text = _messageFrom(error).toLowerCase();
    return text.contains('socketexception') ||
        text.contains('timeout') ||
        text.contains('connection error') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('no internet connection');
  }

  static bool isServerError(Object? error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }

    final text = _messageFrom(error).toLowerCase();
    return text.contains('server error') ||
        text.contains('internal server error') ||
        text.contains('bad gateway') ||
        text.contains('service unavailable');
  }

  static bool isSecureAccessError(Object? error) {
    final text = _messageFrom(error).toLowerCase();
    return text.contains('secure') ||
        text.contains('insecure') ||
        text.contains('webview token') ||
        text.contains('could not open');
  }

  static bool shouldShowDialog(Object? error) {
    return isNetworkError(error) ||
        isServerError(error) ||
        isSecureAccessError(error);
  }

  static String userMessage(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final message = _messageFrom(error).trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid student id') ||
        normalized.contains('email login is not supported') ||
        normalized.contains('incorrect password') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('not agreed')) {
      return _cleanSentence(message);
    }

    if (isNetworkError(error) ||
        normalized.contains('socketexception') ||
        normalized.contains('timeout') ||
        normalized.contains('connection error') ||
        normalized.contains('failed host lookup')) {
      return 'Please check your network connection and try again.';
    }

    if (isServerError(error) ||
        normalized.contains('server') ||
        normalized.contains('bad gateway') ||
        normalized.contains('service unavailable')) {
      return 'The server is unavailable right now. Please try again in a moment.';
    }

    if (isSecureAccessError(error)) {
      return 'Could not open this area securely. Please try again.';
    }

    if (message.isNotEmpty) {
      return _cleanSentence(message);
    }

    return fallback;
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required Object? error,
    String fallback = 'Something went wrong. Please try again.',
    VoidCallback? onRetry,
  }) async {
    final message = userMessage(error, fallback: fallback);
    final visual = visualFor(error);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: visual.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            visual.icon,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visual.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Close'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: visual.accent,
                              side: BorderSide(color: visual.accent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                onRetry();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: visual.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildInlineError({
    required BuildContext context,
    required String title,
    required Object? error,
    required VoidCallback onRetry,
    String fallback = 'Something went wrong. Please try again.',
    IconData icon = Icons.error_outline,
  }) {
    final message = userMessage(error, fallback: fallback);
    final isNetwork = isNetworkError(error);
    final visual = visualFor(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: visual.accent.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: visual.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visual.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textMain,
                ),
              ),
              if (isNetwork) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: visual.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: AppColors.brandGreen,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please check your network connection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: visual.accent.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  isNetwork
                      ? 'The loader will keep trying until the connection comes back.'
                      : 'Use Retry to try the request again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: visual.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _messageFrom(Object? error) {
    if (error == null) return '';
    if (error is DioException) {
      final responseData = error.response?.data;
      final responseMessage = responseData is Map<String, dynamic>
          ? responseData['message']
          : null;
      final message = error.message ?? responseMessage?.toString();
      return message?.trim() ?? error.toString();
    }

    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  static String _cleanSentence(String message) {
    final cleaned = message.replaceFirst('Exception: ', '').trim();
    return cleaned.isEmpty
        ? 'Something went wrong. Please try again.'
        : cleaned;
  }
}

class ErrorVisual {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;

  const ErrorVisual({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.accent,
  });
}
