import 'package:dio/dio.dart';
import '../models/radio_station.dart';
import '../../core/constants/env_config.dart';

class RadioBrowserService {
  final Dio _dio;
  List<RadioStation>? _cache;
  DateTime? _lastFetch;

  static const _cacheDuration = Duration(hours: 6);

  static const _baseUrl = 'https://all.api.radio-browser.info';

  RadioBrowserService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  bool get _isCacheValid =>
      _cache != null &&
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<List<RadioStation>> getStations() async {
    if (_isCacheValid) return _cache!;

    final backend = EnvConfig.backendUrl;
    if (backend.isNotEmpty) {
      return _fetchFromBackend(backend);
    }

    return _fetchFromRadioBrowser();
  }

  Future<List<RadioStation>> _fetchFromBackend(String backend) async {
    try {
      final resp = await _dio
          .get<List<dynamic>>(
            '$backend/api/radio/',
            options: Options(responseType: ResponseType.json),
          )
          .timeout(const Duration(seconds: 15));
      final stations = resp.data!
          .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache = stations;
      _lastFetch = DateTime.now();
      return stations;
    } catch (_) {
      return _fetchFromRadioBrowser();
    }
  }

  Future<List<RadioStation>> _fetchFromRadioBrowser() async {
    final all = <RadioStation>{};
    final results = await Future.wait([
      _fetchList('/json/stations/topclick/500', {'hidebroken': 'true'}),
      _fetchList('/json/stations/topvote/500', {'hidebroken': 'true'}),
      _fetchList('/json/stations/topclick/100', {'hidebroken': 'true', 'tag': 'news'}),
    ], eagerError: false);

    for (final stations in results) {
      all.addAll(stations);
    }

    _cache = all.toList();
    _lastFetch = DateTime.now();
    return _cache!;
  }

  Future<List<RadioStation>> _fetchList(String path, Map<String, dynamic> params) async {
    try {
      final resp = await _dio
          .get<List<dynamic>>(path, queryParameters: params)
          .timeout(const Duration(seconds: 20));
      return resp.data!
          .map((e) => e as Map<String, dynamic>)
          .map(_parseStation)
          .where((s) => s != null)
          .cast<RadioStation>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RadioStation>> searchStations(String query) async {
    final backend = EnvConfig.backendUrl;
    if (backend.isNotEmpty) {
      try {
        final resp = await _dio
            .get<List<dynamic>>(
              '$backend/api/radio/search',
              queryParameters: {'q': query},
              options: Options(responseType: ResponseType.json),
            )
            .timeout(const Duration(seconds: 15));
        return resp.data!
            .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    try {
      final resp = await _dio
          .get<List<dynamic>>(
            '/json/stations/search',
            queryParameters: {
              'name': query,
              'limit': 50,
              'hidebroken': 'true',
            },
          )
          .timeout(const Duration(seconds: 15));
      return resp.data!
          .map((e) => e as Map<String, dynamic>)
          .map(_parseStation)
          .where((s) => s != null)
          .cast<RadioStation>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  RadioStation? _parseStation(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final url = json['url_resolved'] as String? ?? json['url'] as String?;
    if (name == null || url == null) return null;

    final tags = (json['tags'] as String? ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final tag = tags.isNotEmpty ? tags.first : 'General';
    final countryCode = json['countrycode'] as String? ?? '';

    return RadioStation(
      id: 'rb_${json['stationuuid'] as String? ?? name.hashCode.toString()}',
      name: name,
      primaryUrl: url,
      logoUrl: json['favicon'] as String?,
      category: _mapCategory(tag),
      country: countryCode,
      language: json['language'] as String? ?? 'en',
      bitrate: (json['bitrate'] as int?) ?? 128,
      description: json['homepage'] as String?,
    );
  }

  String _mapCategory(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('news') || lower.contains('talk') || lower.contains('sport')) {
      return 'News & Talk';
    }
    if (lower.contains('religious') || lower.contains('gospel') ||
        lower.contains('christian') || lower.contains('islam') ||
        lower.contains('sermon')) {
      return 'Religious';
    }
    if (lower.contains('pop') || lower.contains('rock') || lower.contains('hip hop') ||
        lower.contains('urban') || lower.contains('jazz') || lower.contains('electronic') ||
        lower.contains('dance') || lower.contains('r&b') || lower.contains('reggae')) {
      return 'Music';
    }
    if (lower.contains('country') || lower.contains('folk') ||
        lower.contains('traditional') || lower.contains('cultural')) {
      return 'World & Culture';
    }
    if (lower.contains('public') || lower.contains('community') ||
        lower.contains('university') || lower.contains('college')) {
      return 'Public & Community';
    }
    return 'Music';
  }

  void invalidateCache() {
    _cache = null;
    _lastFetch = null;
  }
}
