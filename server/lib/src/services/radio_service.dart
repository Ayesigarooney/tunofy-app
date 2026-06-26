import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioService {
  final http.Client _client;

  static const _baseUrl = 'https://all.api.radio-browser.info';

  RadioService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RadioStation>> fetchStations() async {
    final all = <RadioStation>{};
    final urls = [
      '$_baseUrl/json/stations/topclick/200',
      '$_baseUrl/json/stations/topvote/200',
    ];

    final responses = await Future.wait(
      urls.map((url) => _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20))
          .catchError((_) => http.Response('[]', 500))),
      eagerError: false,
    );

    for (final resp in responses) {
      if (resp.statusCode == 200) {
        final list = (jsonDecode(resp.body) as List)
            .map((e) => _parseStation(e as Map<String, dynamic>))
            .whereType<RadioStation>()
            .toList();
        all.addAll(list);
      }
    }
    return all.toList();
  }

  Future<List<RadioStation>> searchStations(String query) async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/json/stations/search?name=$query&limit=50&hidebroken=true'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as List)
            .map((e) => _parseStation(e as Map<String, dynamic>))
            .whereType<RadioStation>()
            .toList();
      }
    } catch (_) {}
    return [];
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

  void dispose() {
    _client.close();
  }
}
