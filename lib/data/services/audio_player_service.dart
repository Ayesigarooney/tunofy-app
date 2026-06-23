// lib/data/services/audio_player_service.dart

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/home_widget_service.dart';

class TunoAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  RadioStation? _currentStation;
  int _currentUrlIndex = 0;
  bool _isLoading = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _metadataSubscription;
  Timer? _metadataTimer;

  // Recording state
  bool _isRecording = false;
  String? _recordingFilePath;

  // PiP state
  bool _isInPipMode = false;

  // Stream controllers
  final _metadataController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get metadataStream => _metadataController.stream;

  bool get isRecording => _isRecording;
  String? get recordingFilePath => _recordingFilePath;
  bool get isInPipMode => _isInPipMode;

  set isInPipMode(bool value) => _isInPipMode = value;

  void setRecordingState({required bool recording, String? filePath}) {
    _isRecording = recording;
    _recordingFilePath = filePath;
  }

  TunoAudioHandler() {
    _init();
  }

  void _init() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);

      // Auto-retry on error with fallback URLs
      if (!_isLoading && state.processingState == ProcessingState.idle && _currentStation != null) {
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
    _stopMetadataPolling();
    await _loadUrl(station.primaryUrl);

    // Start metadata polling for custom station
    if (station.isCustomStation) {
      _startMetadataPolling();
    }
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

      // Update media item in notification
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
      await Future.delayed(AppConstants.retryDelay);
      await _loadUrl(urls[_currentUrlIndex]);
    }
    // If all URLs exhausted, stay in idle state
  }

  void _startMetadataPolling() {
    _metadataTimer?.cancel();
    _metadataTimer = Timer.periodic(
      AppConstants.metadataPollingInterval,
      (_) => _fetchMetadata(),
    );
  }

  void _stopMetadataPolling() {
    _metadataTimer?.cancel();
    _metadataTimer = null;
  }

  Future<void> _fetchMetadata() async {
    // Metadata fetching is handled by RadioService via Dio
    // This timer triggers a fetch event that RadioService listens to
    _metadataController.add({'trigger': 'fetch'});
  }

  Future<void> setLowDataMode(bool enabled) async {
    // Force audio-only at 64kbps when low data mode is on
    // For streams that support quality switching, we'd switch to the low-quality variant
    // For standard streams, just continue (audio is already low-data)
    if (enabled) {
      // Could implement bitrate-limited audio source here
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _stopMetadataPolling();
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
    _playerStateSubscription?.cancel();
    _metadataSubscription?.cancel();
    _stopMetadataPolling();
    await _metadataController.close();
    await _player.dispose();
  }
}
