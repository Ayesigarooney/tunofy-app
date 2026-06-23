import 'package:dio/dio.dart';

class ChannelRefreshService {
  final Dio _dio;

  ChannelRefreshService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ));

  Future<String?> refreshFromPage(String pageUrl) async {
    try {
      final response = await _dio.get(pageUrl,
          options: Options(headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36'
          }));
      final html = response.data as String;
      return _extractM3u8(html);
    } catch (_) {
      return null;
    }
  }

  String? _extractM3u8(String html) {
    final regex = RegExp(
      r'<source[^>]+type="application/x-mpegURL"[^>]+src="([^"]+)"',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    return match?.group(1);
  }
}
