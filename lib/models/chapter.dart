class Chapter {
  final int number;
  final String title;
  final String content;

  const Chapter({
    required this.number,
    required this.title,
    required this.content,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        number: json['number'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'number': number, 'title': title, 'content': content};
}
