// lib/data/models/news_article.dart

class NewsArticle {
  final String title;
  final String? description;
  final String? content;
  final String? url;
  final String? imageUrl;
  final String? publishedAt;
  final NewsSource? source;
  final String? author;

  const NewsArticle({
    required this.title,
    this.description,
    this.content,
    this.url,
    this.imageUrl,
    this.publishedAt,
    this.source,
    this.author,
  });

  String get formattedDate {
    if (publishedAt == null) return '';
    try {
      final date = DateTime.parse(publishedAt!);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (_) {
      return publishedAt ?? '';
    }
  }
}

class NewsSource {
  final String? id;
  final String name;

  const NewsSource({this.id, required this.name});
}
