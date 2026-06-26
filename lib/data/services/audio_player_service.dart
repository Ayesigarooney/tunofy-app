// lib/data/services/audio_player_service.dart

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/home_widget_service.dart';

class TunoAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  RadioStation? _currentStation;
  int _currentUrlIndex = 0;
  bool _isLoading = false;
  bool _isTryingFallback = false;
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  TunoAudioHandler() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);

      // Auto-retry with fallback URLs on unexpected idle (error/dropped stream)
      if (!_isLoading &&
          !_isTryingFallback &&
          state.processingState == ProcessingState.idle &&
          _currentStation != null) {
        _tryNextUrl();
      }
    });
  }

  void _updatePlaybackState(PlayerState state) {
    final playing = state.playing;
    final processingState = switch (state.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(PlaybackState(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      processingState: processingState,
      playing: playing,
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
    ));

    if (_currentStation != null) {
      HomeWidgetService.updateNowPlaying(
        stationName: _currentStation!.name,
        stationCategory: _currentStation!.category,
        stationLogoUrl: _currentStation!.logoUrl,
        isPlaying: playing,
      );
    } else {
      HomeWidgetService.clearWidget();
    }
  }

  Future<void> playStation(RadioStation station) async {
    _currentStation = station;
    _currentUrlIndex = 0;
    _isTryingFallback = false;
    await _loadUrl(station.primaryUrl);
  }

  Future<void> _loadUrl(String url) async {
    _isLoading = true;
    try {
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
        preload: true,
      );
      _isLoading = false;
      await _player.play();

      if (_currentStation != null) {
        mediaItem.add(MediaItem(
          id: _currentStation!.id,
          title: _currentStation!.name,
          artist: 'Live Stream',
          album: _currentStation!.category,
          artUri: _currentStation!.logoUrl != null
              ? Uri.parse(_currentStation!.logoUrl!)
              : null,
          displayTitle: _currentStation!.name,
          displaySubtitle: 'Live • ${_currentStation!.category}',
        ));
      }
    } catch (e) {
      _isLoading = false;
      debugPrint('[AudioHandler] Error loading $url: $e');
      await _tryNextUrl();
    }
  }

  Future<void> _tryNextUrl() async {
    if (_currentStation == null) return;

    final urls = [
      _currentStation!.primaryUrl,
      if (_currentStation!.backupUrl1 != null) _currentStation!.backupUrl1!,
      if (_currentStation!.backupUrl2 != null) _currentStation!.backupUrl2!,
    ];

    _currentUrlIndex++;
    if (_currentUrlIndex < urls.length) {
      _isTryingFallback = true;
      await Future<void>.delayed(AppConstants.retryDelay);
      _isTryingFallback = false;
      await _loadUrl(urls[_currentUrlIndex]);
    }
    // All URLs exhausted — stay in idle state, UI will show error
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    _currentStation = null;
    await _player.stop();
    HomeWidgetService.clearWidget();
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  ProcessingState get processingState => _player.processingState;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    _playerStateSubscription.cancel();
    await _player.dispose();
  }
}
