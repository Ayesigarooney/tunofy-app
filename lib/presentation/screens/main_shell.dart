// lib/presentation/screens/main_shell.dart

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
