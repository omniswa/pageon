class ReadingProgress {
  /// Zero-based chapter index.
  final int chapter;
  final int totalChapters;

  /// Scroll position inside the chapter, 0.0 – 1.0.
  final double scroll;
  final DateTime updatedAt;

  ReadingProgress({
    required this.chapter,
    required this.totalChapters,
    required this.scroll,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Overall progress through the book, 0.0 – 1.0.
  double get fraction => totalChapters == 0
      ? 0
      : ((chapter + scroll) / totalChapters).clamp(0.0, 1.0);

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        chapter: json['chapter'] as int,
        totalChapters: json['total'] as int,
        scroll: (json['scroll'] as num).toDouble(),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'total': totalChapters,
        'scroll': scroll,
        'at': updatedAt.millisecondsSinceEpoch,
      };
}
