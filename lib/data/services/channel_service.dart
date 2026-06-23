import 'package:dio/dio.dart';
import '../models/radio_station.dart';
import '../../core/constants/env_config.dart';

class ChannelService {
  final Dio _dio;
  List<TvChannel>? _cache;
  DateTime? _lastFetch;

  static const _cacheDuration = Duration(hours: 6);

  static const _categoryPlaylists = [
    'news', 'sports', 'entertainment', 'music', 'documentary',
    'education', 'kids', 'movies', 'religion', 'general',
    'business', 'science', 'travel', 'animation',
  ];

  static const _baseUrl =
      'https://iptv-org.github.io/iptv/categories';

  ChannelService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  bool get _isCacheValid =>
      _cache != null &&
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<List<TvChannel>> getChannels() async {
    if (_isCacheValid) return _cache!;

    final backend = EnvConfig.backendUrl;
    if (backend.isNotEmpty) {
      return _fetchFromBackend(backend);
    }

    return _fetchFromIptvOrg();
  }

  Future<List<TvChannel>> _fetchFromBackend(String backend) async {
    try {
      final resp = await _dio
          .get<List<dynamic>>(
            '$backend/api/tv/',
            options: Options(responseType: ResponseType.json),
          )
          .timeout(const Duration(seconds: 15));
      final channels = resp.data!
          .map((e) => TvChannel.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache = channels;
      _lastFetch = DateTime.now();
      return channels;
    } catch (_) {
      return _fetchFromIptvOrg();
    }
  }

  Future<List<TvChannel>> _fetchFromIptvOrg() async {
    final all = <TvChannel>{};
    final results = await Future.wait(
      _categoryPlaylists.map((category) => _fetchSingleCategory(category)),
      eagerError: false,
    );
    for (final channels in results) {
      all.addAll(channels);
    }

    final result = all.toList();
    _cache = result;
    _lastFetch = DateTime.now();
    return result;
  }

  Future<List<TvChannel>> _fetchSingleCategory(String category) async {
    try {
      final resp = await _dio
          .get(
            '$_baseUrl/$category.m3u',
            options: Options(responseType: ResponseType.plain),
          )
          .timeout(const Duration(seconds: 10));
      return _parseM3u(resp.data as String, category);
    } catch (_) {
      return [];
    }
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
          final group = _extractTag(pendingExtinf, 'group-title') ?? fallbackCategory;
          final id = _extractTag(pendingExtinf, 'tvg-id') ??
              name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
          final country = _extractCountry(pendingExtinf, id);
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
            country: country,
            description: name,
          ));
          pendingExtinf = null;
        }
      }
    }
    return channels;
  }

  String _normalizeCategory(String raw) {
    // Split on semicolons and take the first meaningful part
    final parts = raw.split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final primary = parts.isNotEmpty ? parts.first : 'General';
    if (primary.isEmpty) return 'General';
    return primary[0].toUpperCase() + primary.substring(1).toLowerCase();
  }

  String _extractCountry(String? line, String tvgId) {
    // First try tvg-country tag
    if (line != null) {
      final tag = _extractTag(line, 'tvg-country');
      if (tag != null && tag.isNotEmpty) return tag.toUpperCase();
    }
    // Then try tvg-id pattern: name.cc@quality
    final match = RegExp(r'\.([a-z]{2})[@.]').firstMatch(tvgId);
    if (match != null) return match.group(1)!.toUpperCase();
    return '';
  }

  String? _extractTag(String line, String tag) {
    final pattern = RegExp('$tag="([^"]*)"');
    final match = pattern.firstMatch(line);
    return match?.group(1);
  }

  void invalidateCache() {
    _cache = null;
    _lastFetch = null;
  }
}
