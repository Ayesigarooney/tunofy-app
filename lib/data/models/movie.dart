// lib/data/models/movie.dart

class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final bool isAdult;
  final String? originalLanguage;
  final String? streamUrl;

  const Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseDate,
    this.genreIds = const [],
    this.isAdult = false,
    this.originalLanguage,
    this.streamUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      isAdult: json['adult'] as bool? ?? false,
      originalLanguage: json['original_language'] as String?,
    );
  }

  String get fullPosterUrl {
    if (posterPath == null) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get fullBackdropUrl {
    if (backdropPath == null) return '';
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }

  String get formattedRating {
    if (voteAverage == null) return 'N/A';
    return voteAverage!.toStringAsFixed(1);
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }
}

class MovieCategory {
  final String id;
  final String name;
  final List<Movie> movies;

  const MovieCategory({
    required this.id,
    required this.name,
    required this.movies,
  });
}
