import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/playlist_store.dart';

Response _json(List<Map<String, dynamic>> data) {
  return Response.ok(
    jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Handler radioHandler(PlaylistStore store) {
  return (Request request) async {
    final uri = request.requestedUri;
    final queryParams = uri.queryParameters;

    if (uri.pathSegments.contains('categories')) {
      return _json(store.radioCategories.map((c) => {'name': c}).toList());
    }

    if (uri.pathSegments.contains('search')) {
      final q = queryParams['q'] ?? '';
      if (q.isEmpty) return _json(store.radioStations.map((s) => s.toJson()).toList());
      final results = store.searchRadio(q);
      return _json(results.map((s) => s.toJson()).toList());
    }

    return _json(store.radioStations.map((s) => s.toJson()).toList());
  };
}
