import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/news_article.dart';

class RssNewsService {
  final Dio _dio;

  static const _sources = [
    'https://feeds.bbci.co.uk/news/world/africa/rss.xml',
    'https://www.theguardian.com/world/africa/rss',
    'https://www.monitor.co.ug/rss.xml',
  ];

  RssNewsService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<List<NewsArticle>> fetchAll({int maxPerSource = 15}) async {
    final results = await Future.wait(
      _sources.map((url) => _fetchSource(url, maxPerSource)),
      eagerError: false,
    );
    final combined = <NewsArticle>[];
    for (final articles in results) {
      combined.addAll(articles);
    }
    combined.sort((a, b) {
      final aDate = _parseDate(a.publishedAt);
      final bDate = _parseDate(b.publishedAt);
      return bDate.compareTo(aDate);
    });
    return combined.take(50).toList();
  }

  Future<List<NewsArticle>> _fetchSource(String url, int max) async {
    try {
      final response = await _dio.get(url);
      final document = XmlDocument.parse(response.data);
      final items = document.findAllElements('item').take(max);
      return items.map(_parseItem).where((a) => a.title.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  NewsArticle _parseItem(XmlElement item) {
    final title = _text(item, 'title') ?? '';
    final description = _text(item, 'description');
    final link = _text(item, 'link');
    final imageUrl = _extractImage(item);
    final pubDate = _text(item, 'pubDate');
    String? sourceName;
    try {
      sourceName = item.findElements('source').first.text;
    } catch (_) {
      sourceName = _extractSourceName(link);
    }

    return NewsArticle(
      title: _stripCdata(title),
      description: _stripHtml(_stripCdata(description ?? '')),
      content: null,
      url: link,
      imageUrl: imageUrl,
      publishedAt: pubDate,
      source: NewsSource(name: sourceName ?? 'News'),
      author: null,
    );
  }

  String? _text(XmlElement parent, String tag) {
    try {
      return parent.findElements(tag).first.innerText;
    } catch (_) {
      return null;
    }
  }

  String? _extractImage(XmlElement item) {
    final mediaContent = _firstOrNull(item.findElements('media:content'));
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }
    final mediaThumbnail = _firstOrNull(item.findElements('media:thumbnail'));
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }
    final enclosure = _firstOrNull(item.findElements('enclosure'));
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  XmlElement? _firstOrNull(Iterable<XmlElement> elements) {
    final it = elements.iterator;
    return it.moveNext() ? it.current : null;
  }

  String? _extractSourceName(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host;
    if (host.contains('bbc')) return 'BBC News';
    if (host.contains('guardian')) return 'The Guardian';
    if (host.contains('monitor')) return 'Daily Monitor';
    return host.replaceFirst('www.', '');
  }

  String _stripCdata(String text) {
    return text.replaceAllMapped(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), (m) => m.group(1) ?? '');
  }

  String _stripHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime(2000);
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        return HttpDate.parse(dateStr);
      } catch (_) {
        return DateTime(2000);
      }
    }
  }
}

class HttpDate {
  static final _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  static DateTime parse(String input) {
    try {
      final parts = input.split(' ');
      if (parts.length < 6) return DateTime(2000);
      final day = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '')) ?? 1;
      final month = _months[parts[2]] ?? 1;
      final timeParts = parts[4].split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final second = int.tryParse(timeParts[2]) ?? 0;
      final yearStr = parts[3].length == 2 ? '20${parts[3]}' : parts[3];
      final year = int.tryParse(yearStr) ?? 2000;
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return DateTime(2000);
    }
  }
}
