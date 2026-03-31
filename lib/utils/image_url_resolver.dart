class ImageUrlResolver {
  static const String _defaultBaseUrl = 'https://elimupepe.loholearning.co.ke';

  static const List<String> _imageKeys = [
    'avatar',
    'avatar_url',
    'avatarUrl',
    'image',
    'image_url',
    'imageUrl',
    'photo',
    'photo_url',
    'photoUrl',
    'cover',
    'cover_url',
    'coverUrl',
    'thumbnail',
    'thumbnail_url',
    'thumbnailUrl',
    'icon',
    'icon_url',
    'iconUrl',
    'banner',
    'banner_url',
    'bannerUrl',
  ];

  static String? fromMap(
    Map<String, dynamic>? data, {
    String baseUrl = _defaultBaseUrl,
  }) {
    if (data == null) return null;

    for (final key in _imageKeys) {
      final normalized = normalize(data[key], baseUrl: baseUrl);
      if (normalized != null) return normalized;
    }

    final nestedCandidates = [data['media'], data['images'], data['image']];
    for (final candidate in nestedCandidates) {
      if (candidate is Map<String, dynamic>) {
        final nested = fromMap(candidate, baseUrl: baseUrl);
        if (nested != null) return nested;
      }
    }

    return null;
  }

  static String? normalize(dynamic raw, {String baseUrl = _defaultBaseUrl}) {
    if (raw == null) return null;

    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }

    if (value.startsWith('www.')) {
      return 'https://$value';
    }

    if (value.contains('/')) {
      return '$baseUrl/$value';
    }

    return null;
  }
}
