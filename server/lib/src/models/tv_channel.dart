class TvChannel {
  final String id;
  final String name;
  final String primaryUrl;
  final String? backupUrl1;
  final String? logoUrl;
  final String category;
  final String country;
  final String description;
  final bool isCustomChannel;

  TvChannel({
    required this.id,
    required this.name,
    required this.primaryUrl,
    this.backupUrl1,
    this.logoUrl,
    required this.category,
    this.country = '',
    this.description = '',
    this.isCustomChannel = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryUrl': primaryUrl,
        'backupUrl1': backupUrl1,
        'logoUrl': logoUrl,
        'category': category,
        'country': country,
        'description': description,
        'isCustomChannel': isCustomChannel,
      };

  factory TvChannel.fromJson(Map<String, dynamic> json) => TvChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryUrl: json['primaryUrl'] as String,
        backupUrl1: json['backupUrl1'] as String?,
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'General',
        country: json['country'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isCustomChannel: json['isCustomChannel'] as bool? ?? false,
      );
}
