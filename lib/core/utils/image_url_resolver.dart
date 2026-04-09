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
    'book_cover',
    'bookCover',
    'cover_image',
    'coverImage',
    'cover_url',
    'coverUrl',
    'cover_path',
    'coverPath',
    'thumbnail',
    'thumbnail_image',
    'thumbnailImage',
    'thumbnail_url',
    'thumbnailUrl',
    'image_path',
    'imagePath',
    'book_image',
    'bookImage',
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

      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map<String, dynamic>) {
            final nested = fromMap(item, baseUrl: baseUrl);
            if (nested != null) return nested;
          } else {
            final normalized = normalize(item, baseUrl: baseUrl);
            if (normalized != null) return normalized;
          }
        }
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
      return Uri.encodeFull(value);
    }

    if (value.startsWith('//')) {
      return Uri.encodeFull('https:$value');
    }

    if (value.startsWith('/')) {
      return Uri.encodeFull('$baseUrl$value');
    }

    if (value.startsWith('www.')) {
      return Uri.encodeFull('https://$value');
    }

    if (value.contains('/')) {
      return Uri.encodeFull('$baseUrl/$value');
    }

    return null;
  }

  static String? withCacheBuster(
    String? url, {
    String? cacheKey,
    String queryKey = 'v',
  }) {
    if (url == null) return null;

    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final key = cacheKey?.trim();
    if (key == null || key.isEmpty) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return trimmed;
    }

    final updatedParams = Map<String, String>.from(uri.queryParameters);
    updatedParams[queryKey] = key;

    return uri.replace(queryParameters: updatedParams).toString();
  }
}
