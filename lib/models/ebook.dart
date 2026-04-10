class Ebook {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? localPath;
  final int totalPages;
  final DateTime? downloadedDate;
  final bool isDownloaded;
  final int fileSize; // in bytes
  final String? serverUrl;
  final String grade; // e.g., "1", "2", "3", etc.
  final String
  category; // e.g., "Textbooks", "Revision Books", "Readers", "Reference Books"
  final String? coverImagePath; // Path to custom thumbnail image

  Ebook({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.localPath,
    required this.totalPages,
    this.downloadedDate,
    required this.isDownloaded,
    required this.fileSize,
    this.serverUrl,
    required this.grade,
    required this.category,
    this.coverImagePath,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'localPath': localPath,
      'totalPages': totalPages,
      'downloadedDate': downloadedDate?.toIso8601String(),
      'isDownloaded': isDownloaded ? 1 : 0,
      'fileSize': fileSize,
      'serverUrl': serverUrl,
      'grade': grade,
      'category': category,
      'coverImagePath': coverImagePath,
    };
  }

  // Create from JSON
  factory Ebook.fromJson(Map<String, dynamic> json) {
    final rawCover =
        json['coverUrl'] ?? json['cover_url'] ?? json['coverImagePath'];
    return Ebook(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description'] as String?,
      coverUrl: rawCover?.toString(),
      localPath: json['localPath'] as String?,
      totalPages: (json['totalPages'] as int?) ?? 0,
      downloadedDate: json['downloadedDate'] != null
          ? DateTime.tryParse(json['downloadedDate'] as String)
          : null,
      isDownloaded: json['isDownloaded'] == 1 || json['isDownloaded'] == true,
      fileSize: (json['fileSize'] as int?) ?? 0,
      serverUrl: json['serverUrl'] as String?,
      grade: json['grade'] as String? ?? '1',
      category: json['category'] as String? ?? 'Textbooks',
      coverImagePath: json['coverImagePath']?.toString(),
    );
  }

  // Copy with method for immutability
  Ebook copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? localPath,
    int? totalPages,
    DateTime? downloadedDate,
    bool? isDownloaded,
    int? fileSize,
    String? serverUrl,
    String? grade,
    String? category,
    String? coverImagePath,
  }) {
    return Ebook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      localPath: localPath ?? this.localPath,
      totalPages: totalPages ?? this.totalPages,
      downloadedDate: downloadedDate ?? this.downloadedDate,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      fileSize: fileSize ?? this.fileSize,
      serverUrl: serverUrl ?? this.serverUrl,
      grade: grade ?? this.grade,
      category: category ?? this.category,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}
