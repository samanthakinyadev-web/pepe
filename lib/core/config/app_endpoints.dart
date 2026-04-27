class AppEndpoints {
  AppEndpoints._();

  static const String primaryHost = 'elimupepe.loholearning.co.ke';
  static const String apiBaseUrl = 'https://$primaryHost/api';
  static const String webBaseUrl = 'https://$primaryHost';
  static const String ebooksApiBaseUrl =
      'https://api-ebooks.loholearning.co.ke';
  static const String secondaryHost = 'loholearning.co.ke';

  static const List<String> trustedHosts = [
    primaryHost,
    secondaryHost,
    'api-ebooks.loholearning.co.ke',
  ];

  static bool isTrustedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    return trustedHosts.contains(uri.host);
  }

  static bool isTrustedUpdateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    return uri.host == primaryHost || uri.host.endsWith('.$primaryHost');
  }
}
