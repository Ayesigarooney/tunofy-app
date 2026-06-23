import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/env_config.dart';
import 'core/security/hive_encryption.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/playlist_server.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/audio_player_service.dart';
import 'data/services/channel_service.dart';
import 'data/services/radio_browser_service.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  final hiveCipher = await HiveEncryption.cipher;
  final favoritesRepo = FavoritesRepository();
  await favoritesRepo.init(encryptionCipher: hiveCipher);
  final settingsRepo = SettingsRepository();
  await settingsRepo.init(encryptionCipher: hiveCipher);

  final audioHandler = await AudioService.init(
    builder: () => TunoAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.tunofy.app.audio',
      androidNotificationChannelName: 'Tunofy Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: const Color(0xFFFF6B00),
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  await NotificationService().init();
  HomeWidgetService.clearWidget();

  if (EnvConfig.serverPort > 0) {
    final server = PlaylistServer(
      channelService: ChannelService(),
      radioService: RadioBrowserService(),
    );
    await server.start(port: EnvConfig.serverPort);
  }

  runApp(
    ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(favoritesRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const TunofyApp(),
    ),
  );
}

class TunofyApp extends ConsumerStatefulWidget {
  const TunofyApp({super.key});

  @override
  ConsumerState<TunofyApp> createState() => _TunofyAppState();
}

class _TunofyAppState extends ConsumerState<TunofyApp> {
  final Set<String> _notifiedNewsUrls = {};

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(newsProvider, (prev, next) {
      next.whenData((articles) {
        if (articles.isEmpty) return;
        final top = articles.first;
        if (top.url != null &&
            !_notifiedNewsUrls.contains(top.url) &&
            _notifiedNewsUrls.isNotEmpty) {
          _notifiedNewsUrls.add(top.url!);
          NotificationService().showNewsNotification(
            title: top.title,
            body: top.description ?? 'Tap to read',
            articleUrl: top.url,
          );
        }
      });
    });

    return MaterialApp(
      title: 'Tunofy',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
