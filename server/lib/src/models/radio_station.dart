class RadioStation {
  final String id;
  final String name;
  final String primaryUrl;
  final String? backupUrl1;
  final String? logoUrl;
  final String category;
  final String country;
  final String language;
  final int bitrate;
  final String? description;
  final bool isCustomStation;

  RadioStation({
    required this.id,
    required this.name,
    required this.primaryUrl,
    this.backupUrl1,
    this.logoUrl,
    required this.category,
    this.country = '',
    this.language = 'en',
    this.bitrate = 128,
    this.description,
    this.isCustomStation = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryUrl': primaryUrl,
        'backupUrl1': backupUrl1,
        'logoUrl': logoUrl,
        'category': category,
        'country': country,
        'language': language,
        'bitrate': bitrate,
        'description': description,
        'isCustomStation': isCustomStation,
      };

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryUrl: json['primaryUrl'] as String,
        backupUrl1: json['backupUrl1'] as String?,
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'Music',
        country: json['country'] as String? ?? '',
        language: json['language'] as String? ?? 'en',
        bitrate: json['bitrate'] as int? ?? 128,
        description: json['description'] as String?,
        isCustomStation: json['isCustomStation'] as bool? ?? false,
      );
}
