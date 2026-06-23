// lib/data/models/player_state.dart

import 'radio_station.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  error,
  buffering,
}

enum PlayerType {
  radio,
  tv,
  none,
}

class StreamMetadata {
  final String? title;
  final String? artist;
  final String? albumArt;
  final int? bitrate;

  const StreamMetadata({
    this.title,
    this.artist,
    this.albumArt,
    this.bitrate,
  });

  StreamMetadata copyWith({
    String? title,
    String? artist,
    String? albumArt,
    int? bitrate,
  }) {
    return StreamMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      bitrate: bitrate ?? this.bitrate,
    );
  }
}

class TunoPlayerState {
  final PlayerStatus status;
  final PlayerType type;
  final RadioStation? currentRadioStation;
  final String? errorMessage;
  final StreamMetadata? metadata;
  final bool isMinimized;
  final double volume;
  final bool isMuted;

  const TunoPlayerState({
    this.status = PlayerStatus.idle,
    this.type = PlayerType.none,
    this.currentRadioStation,
    this.errorMessage,
    this.metadata,
    this.isMinimized = false,
    this.volume = 1.0,
    this.isMuted = false,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading => status == PlayerStatus.loading || status == PlayerStatus.buffering;
  bool get hasError => status == PlayerStatus.error;
  bool get isActive => type != PlayerType.none && status != PlayerStatus.idle;

  TunoPlayerState copyWith({
    PlayerStatus? status,
    PlayerType? type,
    RadioStation? currentRadioStation,
    String? errorMessage,
    StreamMetadata? metadata,
    bool? isMinimized,
    double? volume,
    bool? isMuted,
    bool clearStation = false,
  }) {
    return TunoPlayerState(
      status: status ?? this.status,
      type: type ?? this.type,
      currentRadioStation: clearStation ? null : (currentRadioStation ?? this.currentRadioStation),
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      isMinimized: isMinimized ?? this.isMinimized,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
