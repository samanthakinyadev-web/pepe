class Competency {
  final String name;
  final double progress;

  Competency({required this.name, required this.progress});

  factory Competency.fromJson(Map<String, dynamic> json) {
    return Competency(
      name: json['name'] ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
