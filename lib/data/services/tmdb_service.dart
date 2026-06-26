import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../../core/constants/app_constants.dart';

class TmdbService {
  late final Dio _dio;

  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.tmdbBaseUrl,
      queryParameters: {'api_key': AppConstants.tmdbApiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  Future<List<Movie>> getTrendingMovies() async {
    try {
      final response = await _dio.get('/trending/movie/week');
      final results = response.data['results'] as List<dynamic>;
      return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Movie>> getMoviesByCategory(String category, {int page = 1}) async {
    try {
      final endpoint = switch (category) {
        'action' => '/discover/movie',
        'documentary' => '/discover/movie',
        _ => '/movie/popular',
      };

      final Map<String, dynamic> extra = switch (category) {
        'action' => {'with_genres': '28', 'page': page},
        'documentary' => {'with_genres': '99', 'page': page},
        _ => {'page': page},
      };

      final response = await _dio.get(endpoint, queryParameters: extra);
      final results = response.data['results'] as List<dynamic>;
      return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _dio.get('/search/movie', queryParameters: {'query': query});
      final results = response.data['results'] as List<dynamic>;
      return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Movie>> getAfricanMovies() async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_origin_country': 'NG|ZA|KE|UG|GH|ET|EG',
        'sort_by': 'popularity.desc',
      });
      final results = response.data['results'] as List<dynamic>;
      return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> getMovieTrailerKey(int movieId) async {
    try {
      final response = await _dio.get('/movie/$movieId/videos');
      final results = response.data['results'] as List<dynamic>;
      for (final v in results) {
        final site = v['site'] as String?;
        final type = v['type'] as String?;
        final key = v['key'] as String?;
        if (site == 'YouTube' && type == 'Trailer' && key != null && key.isNotEmpty) {
          return key;
        }
      }
      for (final v in results) {
        final site = v['site'] as String?;
        final key = v['key'] as String?;
        if (site == 'YouTube' && key != null && key.isNotEmpty) {
          return key;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
