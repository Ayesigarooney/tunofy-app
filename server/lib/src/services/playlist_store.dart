import 'dart:async';
import '../models/tv_channel.dart';
import '../models/radio_station.dart';
import 'm3u_service.dart';
import 'radio_service.dart';

class PlaylistStore {
  final M3uService _m3u;
  final RadioService _radio;

  List<TvChannel> _tvChannels = [];
  List<RadioStation> _radioStations = [];
  Timer? _refreshTimer;

  static const _refreshInterval = Duration(hours: 6);

  PlaylistStore({M3uService? m3u, RadioService? radio})
      : _m3u = m3u ?? M3uService(),
        _radio = radio ?? RadioService();

  List<TvChannel> get tvChannels => _tvChannels;
  List<RadioStation> get radioStations => _radioStations;

  List<String> get tvCategories {
    final cats = <String>{};
    for (final c in _tvChannels) {
      if (!c.isCustomChannel && c.category.isNotEmpty) {
        cats.add(c.category);
      }
    }
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get radioCategories {
    final cats = <String>{};
    for (final s in _radioStations) {
      if (!s.isCustomStation && s.category.isNotEmpty) {
        cats.add(s.category);
      }
    }
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  Future<void> startPeriodicRefresh() async {
    await refreshAll();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => refreshAll());
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshTvChannels(),
      refreshRadioStations(),
    ]);
  }

  Future<void> refreshTvChannels() async {
    try {
      final channels = await _m3u.fetchChannels();
      if (channels.isNotEmpty) _tvChannels = _buildTvList(channels);
    } catch (e) {
      print('[PlaylistStore] TV refresh failed: $e');
    }
  }

  Future<void> refreshRadioStations() async {
    try {
      final stations = await _radio.fetchStations();
      if (stations.isNotEmpty) _radioStations = _buildRadioList(stations);
    } catch (e) {
      print('[PlaylistStore] Radio refresh failed: $e');
    }
  }

  List<TvChannel> searchTv(String query) {
    final lower = query.toLowerCase();
    return _tvChannels.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      c.category.toLowerCase().contains(lower) ||
      c.country.toLowerCase().contains(lower)
    ).toList();
  }

  List<RadioStation> searchRadio(String query) {
    final lower = query.toLowerCase();
    return _radioStations.where((s) =>
      s.name.toLowerCase().contains(lower) ||
      s.category.toLowerCase().contains(lower) ||
      s.country.toLowerCase().contains(lower)
    ).toList();
  }

  List<TvChannel> _buildTvList(List<TvChannel> fetched) => fetched;
  List<RadioStation> _buildRadioList(List<RadioStation> fetched) => fetched;

  void dispose() {
    _refreshTimer?.cancel();
    _m3u.dispose();
    _radio.dispose();
  }
}
