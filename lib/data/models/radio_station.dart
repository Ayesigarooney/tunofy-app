// lib/data/models/radio_station.dart

import 'package:hive/hive.dart';

part 'radio_station.g.dart';

@HiveType(typeId: 0)
class RadioStation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String primaryUrl;

  @HiveField(3)
  final String? backupUrl1;

  @HiveField(4)
  final String? backupUrl2;

  @HiveField(5)
  final String? logoUrl;

  @HiveField(6)
  final String category;

  @HiveField(7)
  final String? country;

  @HiveField(8)
  final String? language;

  @HiveField(9)
  final bool isCustomStation;

  @HiveField(10)
  final int? bitrate;

  @HiveField(11)
  final String? description;

  RadioStation({
    required this.id,
    required this.name,
    required this.primaryUrl,
    this.backupUrl1,
    this.backupUrl2,
    this.logoUrl,
    required this.category,
    this.country,
    this.language,
    this.isCustomStation = false,
    this.bitrate,
    this.description,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryUrl: json['primaryUrl'] as String,
        backupUrl1: json['backupUrl1'] as String?,
        backupUrl2: json['backupUrl2'] as String?,
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'Music',
        country: json['country'] as String?,
        language: json['language'] as String?,
        isCustomStation: json['isCustomStation'] as bool? ?? false,
        bitrate: json['bitrate'] as int?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryUrl': primaryUrl,
        'backupUrl1': backupUrl1,
        'backupUrl2': backupUrl2,
        'logoUrl': logoUrl,
        'category': category,
        'country': country,
        'language': language,
        'isCustomStation': isCustomStation,
        'bitrate': bitrate,
        'description': description,
      };

  RadioStation copyWith({
    String? id,
    String? name,
    String? primaryUrl,
    String? backupUrl1,
    String? backupUrl2,
    String? logoUrl,
    String? category,
    String? country,
    String? language,
    bool? isCustomStation,
    int? bitrate,
    String? description,
  }) {
    return RadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryUrl: primaryUrl ?? this.primaryUrl,
      backupUrl1: backupUrl1 ?? this.backupUrl1,
      backupUrl2: backupUrl2 ?? this.backupUrl2,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      country: country ?? this.country,
      language: language ?? this.language,
      isCustomStation: isCustomStation ?? this.isCustomStation,
      bitrate: bitrate ?? this.bitrate,
      description: description ?? this.description,
    );
  }
}

// lib/data/models/tv_channel.dart

@HiveType(typeId: 1)
class TvChannel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String primaryUrl;

  @HiveField(3)
  final String? backupUrl1;

  @HiveField(4)
  final String? backupUrl2;

  @HiveField(5)
  final String? logoUrl;

  @HiveField(6)
  final String category;

  @HiveField(7)
  final bool isCustomChannel;

  @HiveField(8)
  final String? description;

  @HiveField(9)
  final String? country;

  TvChannel({
    required this.id,
    required this.name,
    required this.primaryUrl,
    this.backupUrl1,
    this.backupUrl2,
    this.logoUrl,
    required this.category,
    this.isCustomChannel = false,
    this.description,
    this.country,
  });

  factory TvChannel.fromJson(Map<String, dynamic> json) => TvChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryUrl: json['primaryUrl'] as String,
        backupUrl1: json['backupUrl1'] as String?,
        backupUrl2: json['backupUrl2'] as String?,
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'General',
        isCustomChannel: json['isCustomChannel'] as bool? ?? false,
        description: json['description'] as String?,
        country: json['country'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryUrl': primaryUrl,
        'backupUrl1': backupUrl1,
        'backupUrl2': backupUrl2,
        'logoUrl': logoUrl,
        'category': category,
        'isCustomChannel': isCustomChannel,
        'description': description,
        'country': country,
      };
}
