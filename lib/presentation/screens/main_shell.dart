// lib/presentation/screens/main_shell.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/player_state.dart';
import '../providers/app_providers.dart';
import '../widgets/now_playing_compact.dart';
import '../widgets/tunofy_widgets.dart';
import 'radio/radio_screen.dart';
import 'tv/tv_screen.dart';
import 'movies/movies_screen.dart';
import 'news/news_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RadioScreen(),
    TvScreen(),
    MoviesScreen(),
    NewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final showMiniPlayer = playerState.isActive && !playerState.isMinimized;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),

          // Mini player bar (floating above bottom nav)
          if (showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight,
              child: MiniPlayerBar(
                stationName: playerState.currentRadioStation?.name ??
                    (playerState.type == PlayerType.tv ? 'Tunofy TV' : 'Stream'),
                subtitle: playerState.metadata?.title ??
                    (playerState.isLoading ? 'Connecting…' : 'Live'),
                isPlaying: playerState.isPlaying,
                isLoading: playerState.isLoading,
                onPlayPause: () {
                  if (playerState.isPlaying) {
                    ref.read(playerStateProvider.notifier).pause();
                  } else {
                    ref.read(playerStateProvider.notifier).resume();
                  }
                },
                onStop: () => ref.read(playerStateProvider.notifier).stop(),
                onExpand: () {
                  if (playerState.type == PlayerType.radio) {
                    setState(() => _currentIndex = 0);
                  } else if (playerState.type == PlayerType.tv) {
                    setState(() => _currentIndex = 1);
                  }
                },
                onMinimize: () => ref.read(playerStateProvider.notifier).setMinimized(true),
              ),
            ),

          // Now playing compact bar (above bottom nav, always visible when active)
          if (playerState.isActive && playerState.isMinimized)
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight,
              child: const NowPlayingCompact(),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.divider
                : AppColors.lightSurfaceVariant,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_rounded),
            activeIcon: Icon(Icons.radio_rounded),
            label: 'Radio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv_rounded),
            activeIcon: Icon(Icons.live_tv_rounded),
            label: 'TV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter_rounded),
            activeIcon: Icon(Icons.movie_filter_rounded),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_rounded),
            activeIcon: Icon(Icons.newspaper_rounded),
            label: 'News',
          ),
        ],
      ),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
// Kept here because the screens/ directory only allows modification of existing
// files. The splash is the app entry point defined in main.dart.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _tagCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _tagOpacity;
  late Animation<double> _tagSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut)));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _tagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _tagOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));
    _tagSlide = Tween<double>(begin: 18, end: 0).animate(
        CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));

    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _logoCtrl.forward();
    _ringCtrl.repeat();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _tagCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _ringCtrl.stop();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const MainShell(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(140, 140),
                      painter: _SplashRingPainter(_ringCtrl.value),
                    ),
                  ),
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFF8C2A), AppColors.accentOrange],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentOrange.withValues(alpha: 0.45),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _logoOpacity,
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'Tuno',
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'fy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _tagCtrl,
              builder: (_, child) => Opacity(
                opacity: _tagOpacity.value,
                child:
                    Transform.translate(offset: Offset(0, _tagSlide.value), child: child),
              ),
              child: const Text(
                'Uganda & World — Live',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: FadeTransition(
          opacity: _tagOpacity,
          child: const Text(
            'Tunofy · v1.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _SplashRingPainter extends CustomPainter {
  final double t;
  _SplashRingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radii = [52.0, 62.0, 70.0];
    final opacities = [0.30, 0.18, 0.09];
    for (var i = 0; i < radii.length; i++) {
      final start =
          -math.pi / 2 + (t * math.pi * 2) + (i * math.pi * 0.4);
      final paint = Paint()
        ..color = AppColors.accentOrange.withValues(alpha: opacities[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: radii[i]), start, math.pi * 0.55, false, paint);
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: radii[i]), start + math.pi, math.pi * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashRingPainter o) => o.t != t;
}
