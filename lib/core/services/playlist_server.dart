import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../data/services/channel_service.dart';
import '../../data/services/radio_browser_service.dart';

class PlaylistServer {
  final ChannelService _channelService;
  final RadioBrowserService _radioService;
  HttpServer? _server;
  Timer? _refreshTimer;

  static const _refreshInterval = Duration(hours: 6);

  PlaylistServer({
    required ChannelService channelService,
    required RadioBrowserService radioService,
  })  : _channelService = channelService,
        _radioService = radioService;

  Future<void> start({int port = 8080, String host = '0.0.0.0'}) async {
    if (_server != null) return;

    final router = Router()
      ..get('/health', (_) => Response.ok(
        '{"status":"ok"}',
        headers: {'content-type': 'application/json'},
      ))
      ..get('/api/tv/', (_) => _tvResponse())
      ..get('/api/tv/categories', (_) => _tvCategoriesResponse())
      ..get('/api/tv/search', (Request request) => _tvSearchResponse(request))
      ..get('/api/radio/', (_) => _radioResponse())
      ..get('/api/radio/categories', (_) => _radioCategoriesResponse())
      ..get('/api/radio/search', (Request request) => _radioSearchResponse(request));

    final handler = const Pipeline()
        .addMiddleware(corsHeaders())
        .addHandler(router);

    _server = await shelf_io.serve(handler, host, port);
    print('Playlist server running on http://${host}:${port}');

    _startPeriodicRefresh();
  }

  Future<void> stop() async {
    _refreshTimer?.cancel();
    await _server?.close(force: true);
    _server = null;
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await Future.wait([
        _channelService.getChannels(),
        _radioService.getStations(),
      ]);
    });
  }

  Response _jsonList(List<Map<String, dynamic>> data) => Response.ok(
    jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );

  Future<Response> _tvResponse() async {
    final channels = await _channelService.getChannels();
    return _jsonList(channels.map((c) => c.toJson()).toList());
  }

  Future<Response> _tvCategoriesResponse() async {
    final channels = await _channelService.getChannels();
    final cats = <String>{};
    for (final c in channels) {
      if (!c.isCustomChannel && c.category.isNotEmpty) {
        cats.add(c.category);
      }
    }
    final sorted = ['All', ...cats.toList()..sort()];
    return _jsonList(sorted.map((c) => {'name': c}).toList());
  }

  Future<Response> _tvSearchResponse(Request request) async {
    final q = request.requestedUri.queryParameters['q'] ?? '';
    final channels = await _channelService.getChannels();
    if (q.isEmpty) return _jsonList(channels.map((c) => c.toJson()).toList());
    final lower = q.toLowerCase();
    final results = channels.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      c.category.toLowerCase().contains(lower) ||
      (c.country?.toLowerCase().contains(lower) ?? false)
    ).toList();
    return _jsonList(results.map((c) => c.toJson()).toList());
  }

  Future<Response> _radioResponse() async {
    final stations = await _radioService.getStations();
    return _jsonList(stations.map((s) => s.toJson()).toList());
  }

  Future<Response> _radioCategoriesResponse() async {
    final stations = await _radioService.getStations();
    final cats = <String>{};
    for (final s in stations) {
      if (!s.isCustomStation && s.category.isNotEmpty) {
        cats.add(s.category);
      }
    }
    final sorted = ['All', ...cats.toList()..sort()];
    return _jsonList(sorted.map((c) => {'name': c}).toList());
  }

  Future<Response> _radioSearchResponse(Request request) async {
    final q = request.requestedUri.queryParameters['q'] ?? '';
    final stations = await _radioService.getStations();
    if (q.isEmpty) return _jsonList(stations.map((s) => s.toJson()).toList());
    final lower = q.toLowerCase();
    final results = stations.where((s) =>
      s.name.toLowerCase().contains(lower) ||
      s.category.toLowerCase().contains(lower) ||
      (s.country?.toLowerCase().contains(lower) ?? false)
    ).toList();
    return _jsonList(results.map((s) => s.toJson()).toList());
  }

  int? get port => _server?.port;
  bool get isRunning => _server != null;
}
