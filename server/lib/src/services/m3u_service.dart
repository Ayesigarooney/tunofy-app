import 'package:http/http.dart' as http;
import '../models/tv_channel.dart';

class M3uService {
  final http.Client _client;

  static const _baseUrl =
      'https://iptv-org.github.io/iptv/categories';

  static const _categories = [
    'news', 'sports', 'entertainment', 'music', 'documentary',
    'education', 'kids', 'movies', 'religion', 'general',
    'business', 'science', 'travel', 'animation',
  ];

  M3uService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TvChannel>> fetchChannels() async {
    final all = <TvChannel>{};
    for (final category in _categories) {
      try {
        final resp = await _client
            .get(Uri.parse('$_baseUrl/$category.m3u'))
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          all.addAll(_parseM3u(resp.body, category));
        }
      } catch (_) {}
    }
    return all.toList();
  }

  List<TvChannel> _parseM3u(String raw, String fallbackCategory) {
    final channels = <TvChannel>[];
    final seen = <String>{};
    final lines = raw.split('\n');
    String? pendingExtinf;

    for (final line in lines) {
      if (line.startsWith('#EXTINF:')) {
        pendingExtinf = line;
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (pendingExtinf != null) {
          final name = _extractTag(pendingExtinf, 'tvg-name') ??
              pendingExtinf.split(',').last.trim();
          final logo = _extractTag(pendingExtinf, 'tvg-logo');
          final group =
              _extractTag(pendingExtinf, 'group-title') ?? fallbackCategory;
          final id = _extractTag(pendingExtinf, 'tvg-id') ??
              name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
          final url = line.trim();

          if (name.isEmpty || url.isEmpty) {
            pendingExtinf = null;
            continue;
          }

          final dedupKey = '$name|$url';
          if (seen.contains(dedupKey)) {
            pendingExtinf = null;
            continue;
          }
          seen.add(dedupKey);

          channels.add(TvChannel(
            id: 'iptv_${id}_${name.hashCode}',
            name: name,
            primaryUrl: url,
            logoUrl: logo,
            category: _normalizeCategory(group),
            country: '',
            description: name,
          ));
          pendingExtinf = null;
        }
      }
    }
    return channels;
  }

  String _normalizeCategory(String raw) {
    final c = raw.trim();
    if (c.isEmpty) return 'General';
    return c[0].toUpperCase() + c.substring(1);
  }

  String? _extractTag(String line, String tag) {
    final pattern = RegExp('$tag="([^"]*)"');
    final match = pattern.firstMatch(line);
    return match?.group(1);
  }

  void dispose() {
    _client.close();
  }
}
