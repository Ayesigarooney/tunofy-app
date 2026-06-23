// lib/data/models/news_article.dart

class NewsArticle {
  final String? id;
  final String title;
  final String? description;
  final String? content;
  final String? url;
  final String? imageUrl;
  final String? publishedAt;
  final NewsSource? source;
  final String? author;

  const NewsArticle({
    this.id,
    required this.title,
    this.description,
    this.content,
    this.url,
    this.imageUrl,
    this.publishedAt,
    this.source,
    this.author,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String?,
      imageUrl: json['urlToImage'] as String?,
      publishedAt: json['publishedAt'] as String?,
      source: json['source'] != null
          ? NewsSource.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      author: json['author'] as String?,
    );
  }

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

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown',
    );
  }
}
