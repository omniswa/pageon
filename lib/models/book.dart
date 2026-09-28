class Book {
  final int id;
  final String title;
  final String author;
  final String cover;
  final String zip;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.zip,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String? ?? 'Unknown author',
      cover: json['cover'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
    );
  }
}
