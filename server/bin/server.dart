import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:tunofy_server/src/handlers/radio_handler.dart';
import 'package:tunofy_server/src/handlers/tv_handler.dart';
import 'package:tunofy_server/src/services/playlist_store.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  final store = PlaylistStore();
  await store.startPeriodicRefresh();

  final router = Router()
    ..get('/health', (request) => Response.ok('{"status":"ok"}', headers: {'content-type': 'application/json'}))
    ..mount('/api/tv/', tvHandler(store))
    ..mount('/api/radio/', radioHandler(store));

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await shelf_io.serve(handler, host, port);
  print('Tunofy server running on http://${host}:${port}');
  print('Endpoints:');
  print('  GET /health');
  print('  GET /api/tv/');
  print('  GET /api/tv/categories');
  print('  GET /api/tv/search?q=...');
  print('  GET /api/radio/');
  print('  GET /api/radio/categories');
  print('  GET /api/radio/search?q=...');

  ProcessSignal.sigint.watch().listen((_) {
    print('Shutting down...');
    store.dispose();
    server.close();
  });
}
