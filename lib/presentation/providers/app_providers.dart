// lib/presentation/providers/app_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/radio_station.dart';
import '../../data/models/player_state.dart';
import '../../data/models/movie.dart';
import '../../data/models/news_article.dart';
import '../../data/repositories/stations_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/services/rss_news_service.dart';
import '../../data/services/audio_player_service.dart';

// ─── Singleton Services ───────────────────────────────────────────────────────

final stationsRepositoryProvider = Provider<StationsRepository>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return StationsRepository(settingsRepository: settingsRepo);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

final newsServiceProvider = Provider<RssNewsService>((ref) {
  return RssNewsService();
});

final audioHandlerProvider = Provider<TunoAudioHandler>((ref) {
  return TunoAudioHandler();
});

// ─── Settings ────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(settings);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settings;

  ThemeModeNotifier(this._settings) : super(_settings.themeMode);

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    state = mode;
  }
}

final lowDataModeProvider = StateNotifierProvider<LowDataModeNotifier, bool>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return LowDataModeNotifier(settings);
});

class LowDataModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _settings;

  LowDataModeNotifier(this._settings) : super(_settings.lowDataMode);

  Future<void> toggle() async {
    final newValue = !state;
    await _settings.setLowDataMode(newValue);
    state = newValue;
  }
}

// ─── Player State ─────────────────────────────────────────────────────────────

final playerStateProvider = StateNotifierProvider<PlayerStateNotifier, TunoPlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final favorites = ref.watch(favoritesRepositoryProvider);
  return PlayerStateNotifier(handler, favorites);
});

class PlayerStateNotifier extends StateNotifier<TunoPlayerState> {
  final TunoAudioHandler _handler;
  final FavoritesRepository _favorites;

  PlayerStateNotifier(this._handler, this._favorites)
      : super(const TunoPlayerState()) {
    _listenToPlayerState();
  }

  void _listenToPlayerState() {
    _handler.playerStateStream.listen((ps) {
      final status = switch (ps.processingState) {
        ProcessingState.idle => PlayerStatus.idle,
        ProcessingState.loading => PlayerStatus.loading,
        ProcessingState.buffering => PlayerStatus.buffering,
        ProcessingState.ready => ps.playing ? PlayerStatus.playing : PlayerStatus.paused,
        ProcessingState.completed => PlayerStatus.idle,
      };
      state = state.copyWith(status: status);
    });
  }

  Future<void> playRadio(RadioStation station) async {
    state = state.copyWith(
      status: PlayerStatus.loading,
      type: PlayerType.radio,
      currentRadioStation: station,
    );
    await _favorites.addRecentlyPlayed(station.id, 'radio');
    try {
      await _handler.playStation(station);
      state = state.copyWith(status: PlayerStatus.playing);
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Failed to connect to stream',
      );
    }
  }

  Future<void> pause() async {
    await _handler.pause();
    state = state.copyWith(status: PlayerStatus.paused);
  }

  Future<void> resume() async {
    await _handler.play();
    state = state.copyWith(status: PlayerStatus.playing);
  }

  Future<void> stop() async {
    await _handler.stop();
    state = const TunoPlayerState();
  }

  void setMinimized(bool minimized) {
    state = state.copyWith(isMinimized: minimized);
  }

  void updateMetadata(StreamMetadata metadata) {
    state = state.copyWith(metadata: metadata);
  }
}

// ─── Offline ──────────────────────────────────────────────────────────────────

final offlineModeProvider = StateProvider<bool>((ref) => false);

// ─── Radio ────────────────────────────────────────────────────────────────────

final radioStationsProvider = FutureProvider<List<RadioStation>>((ref) async {
  final repo = ref.watch(stationsRepositoryProvider);
  final stations = await repo.getRadioStations();
  ref.read(offlineModeProvider.notifier).state = repo.isOffline;
  return stations;
});

final selectedRadioCategoryProvider = StateProvider<String>((ref) => 'All');

final radioSortProvider = StateProvider<String>((ref) => 'Default');

final filteredRadioStationsProvider = FutureProvider<List<RadioStation>>((ref) async {
  final stations = await ref.watch(radioStationsProvider.future);
  final category = ref.watch(selectedRadioCategoryProvider);
  final sort = ref.watch(radioSortProvider);
  var result = category == 'All'
      ? stations.where((s) => !s.isCustomStation).toList()
      : stations.where((s) => s.category == category && !s.isCustomStation).toList();
  try {
    switch (sort) {
      case 'Country':
        result.sort((a, b) => (a.country ?? '').toLowerCase().compareTo((b.country ?? '').toLowerCase()));
        break;
      case 'Name':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
  } catch (_) {}
  return result;
});

final radioCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(stationsRepositoryProvider);
  await ref.watch(radioStationsProvider.future);
  return repo.getRadioCategories();
});

// ─── TV ───────────────────────────────────────────────────────────────────────

final tvChannelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final repo = ref.watch(stationsRepositoryProvider);
  final channels = await repo.getTvChannels();
  ref.read(offlineModeProvider.notifier).state = repo.isOffline;
  return channels;
});

final selectedTvCategoryProvider = StateProvider<String>((ref) => 'All');

final tvSortProvider = StateProvider<String>((ref) => 'Default');

final filteredTvChannelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final channels = await ref.watch(tvChannelsProvider.future);
  final category = ref.watch(selectedTvCategoryProvider);
  final sort = ref.watch(tvSortProvider);
  var result = category == 'All'
      ? channels.where((c) => !c.isCustomChannel).toList()
      : channels.where((c) => c.category == category && !c.isCustomChannel).toList();
  try {
    switch (sort) {
      case 'Country':
        result.sort((a, b) => (a.country ?? '').toLowerCase().compareTo((b.country ?? '').toLowerCase()));
        break;
      case 'Name':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
  } catch (_) {}
  return result;
});

final tvCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(stationsRepositoryProvider);
  await ref.watch(tvChannelsProvider.future);
  return repo.getTvCategories();
});

// ─── Movies ───────────────────────────────────────────────────────────────────

final moviesProvider = FutureProvider<List<MovieCategory>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);

  final results = await Future.wait([
    service.getTrendingMovies(),
    service.getMoviesByCategory('action'),
    service.getMoviesByCategory('documentary'),
    service.getAfricanMovies(),
  ]);

  return [
    MovieCategory(id: 'trending', name: 'Trending Media', movies: results[0]),
    MovieCategory(id: 'action', name: 'Action & Thrillers', movies: results[1]),
    MovieCategory(id: 'documentary', name: 'Documentary Favorites', movies: results[2]),
    MovieCategory(id: 'african', name: 'Local Cinematic Translations', movies: results[3]),
  ];
});

final movieSearchQueryProvider = StateProvider<String>((ref) => '');

final movieSearchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(movieSearchQueryProvider);
  if (query.isEmpty) return [];
  final service = ref.watch(tmdbServiceProvider);
  return service.searchMovies(query);
});

// ─── News ─────────────────────────────────────────────────────────────────────

final newsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchAll(maxPerSource: 15);
});

final selectedNewsArticleProvider = StateProvider<NewsArticle?>((ref) => null);

// ─── Favorites ────────────────────────────────────────────────────────────────

final favoriteIdsProvider = StateNotifierProvider<FavoriteIdsNotifier, Set<String>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoriteIdsNotifier(repo);
});

class FavoriteIdsNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository _repo;

  FavoriteIdsNotifier(this._repo)
      : super(Set.from(_repo.getFavoriteIds()));

  Future<void> toggle(String id, String type) async {
    await _repo.toggleFavorite(id, type);
    state = Set.from(_repo.getFavoriteIds());
  }

  bool isFavorite(String id) => state.contains(id);
}
