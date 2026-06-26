// lib/presentation/widgets/tunofy_widgets.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

/// ─── Section Header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accentOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ─── Live Badge ──────────────────────────────────────────────────────────────

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.liveRed,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Category Chips ──────────────────────────────────────────────────────────

class CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentOrange
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ─── Station Card ────────────────────────────────────────────────────────────

class StationCard extends StatelessWidget {
  final String id;
  final String name;
  final String? logoUrl;
  final String subtitle;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const StationCard({
    super.key,
    required this.id,
    required this.name,
    this.logoUrl,
    required this.subtitle,
    this.isPlaying = false,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.accentOrange.withValues(alpha: 0.12)
              : (isDark ? AppColors.surface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: isPlaying
              ? Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _LogoPlaceholder(),
                      errorWidget: (_, __, ___) => _LogoPlaceholder(),
                    )
                  : _LogoPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Name & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isPlaying ? AppColors.accentOrange : null,
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isPlaying) ...[
                        const LiveBadge(),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite + play button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFavorite ? AppColors.accentOrange : Theme.of(context).iconTheme.color,
                    size: 22,
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                if (isPlaying)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: _AudioWave(),
                  )
                else
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.accentOrange,
                    size: 28,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'T',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'f',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioWave extends StatefulWidget {
  const _AudioWave();

  @override
  State<_AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<_AudioWave> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (i) {
            final heights = [0.4, 1.0, 0.7, 0.9];
            final offsets = [0.0, 0.3, 0.6, 0.1];
            final t = (_ctrl.value + offsets[i]) % 1.0;
            final h = 4.0 + (t * heights[i] * 14);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ─── Movie Poster Card ───────────────────────────────────────────────────────

class MoviePosterCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final String? rating;
  final String? year;
  final VoidCallback onTap;

  const MoviePosterCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.rating,
    this.year,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (posterUrl != null && posterUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ShimmerBox(),
                        errorWidget: (_, __, ___) => const Icon(Icons.movie_outlined),
                      )
                    else
                      const Center(child: Icon(Icons.movie_outlined, size: 36)),
                    if (rating != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 10),
                              const SizedBox(width: 2),
                              Text(
                                rating!,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (year != null && year!.isNotEmpty)
              Text(year!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.surfaceElevated : Colors.white,
      child: Container(color: AppColors.surface),
    );
  }
}

/// ─── Mini Player Bar ─────────────────────────────────────────────────────────

class MiniPlayerBar extends StatelessWidget {
  final String stationName;
  final String? subtitle;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onExpand;
  final VoidCallback? onMinimize;

  const MiniPlayerBar({
    super.key,
    required this.stationName,
    this.subtitle,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    required this.onStop,
    required this.onExpand,
    this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onMinimize?.call();
        }
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radio, color: AppColors.accentOrange, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentOrange,
                    ),
                  )
                : IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.accentOrange,
                      size: 26,
                    ),
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: EdgeInsets.zero,
                  ),
            IconButton(
              onPressed: onStop,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Theme.of(context).iconTheme.color,
              constraints: const BoxConstraints(minWidth: 36),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// ─── Error Widget ────────────────────────────────────────────────────────────

class TunoErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TunoErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Theme.of(context).iconTheme.color),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ─── Loading shimmer list ────────────────────────────────────────────────────

// ─── Offline Banner ──────────────────────────────────────────────────────────

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineModeProvider);
    if (!offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.liveRed.withValues(alpha: 0.9),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Offline — showing cached stations',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Branded Title ────────────────────────────────────────────────────────────

class TunofyTitle extends StatelessWidget {
  final String subtitle;
  final Color subtitleColor;

  const TunofyTitle({
    super.key,
    required this.subtitle,
    this.subtitleColor = AppColors.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tuno',
          style: const TextStyle(
            color: AppColors.accentOrange,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        Text(
          'fy',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: subtitleColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Skeleton Loaders ─────────────────────────────────────────────────────────

class RadioSkeleton extends StatelessWidget {
  const RadioSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant;
    final highlight = isDark ? AppColors.surfaceElevated : Colors.white;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: [
          _skeletonSectionHeader(),
          _skeletonHorizontalScroll(),
          _skeletonSectionHeader(),
          _skeletonHorizontalScroll(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _skeletonBox(width: 80, height: 28),
                const SizedBox(width: 8),
                _skeletonBox(width: 100, height: 28),
                const SizedBox(width: 8),
                _skeletonBox(width: 70, height: 28),
                const Spacer(),
                _skeletonBox(width: 36, height: 28),
              ],
            ),
          ),
          for (var i = 0; i < 5; i++) _skeletonStationRow(),
        ],
      ),
    );
  }

  Widget _skeletonSectionHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(
      children: [
        _SkeletonBlock(width: 100, height: 20),
        Spacer(),
        _SkeletonBlock(width: 50, height: 14),
      ],
    ),
  );

  Widget _skeletonHorizontalScroll() => SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: _SkeletonBlock(width: 100, height: 110),
      ),
    ),
  );

  Widget _skeletonStationRow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      children: [
        _SkeletonBlock(width: 48, height: 48, borderRadius: 10),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: double.infinity, height: 14),
              SizedBox(height: 6),
              _SkeletonBlock(width: 140, height: 12),
            ],
          ),
        ),
        _SkeletonBlock(width: 24, height: 24, borderRadius: 12),
      ],
    ),
  );

  Widget _skeletonBox({required double width, required double height}) =>
      _SkeletonBlock(width: width, height: height, borderRadius: 6);
}

class TvSkeleton extends StatelessWidget {
  const TvSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant;
    final highlight = isDark ? AppColors.surfaceElevated : Colors.white;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _skeletonChip(60), const SizedBox(width: 6),
                _skeletonChip(80), const SizedBox(width: 6),
                _skeletonChip(70), const SizedBox(width: 6),
                _skeletonChip(90), const SizedBox(width: 6),
                _skeletonChip(55),
              ],
            ),
          ),
          for (var r = 0; r < 4; r++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _skeletonCard(),
                  const SizedBox(width: 8),
                  _skeletonCard(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _skeletonChip(double w) => _SkeletonBlock(width: w, height: 28, borderRadius: 14);
  Widget _skeletonCard() => const Expanded(
    child: _SkeletonBlock(width: double.infinity, height: 140, borderRadius: 10),
  );
}

class MoviesSkeleton extends StatelessWidget {
  const MoviesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant;
    final highlight = isDark ? AppColors.surfaceElevated : Colors.white;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  _SkeletonBlock(width: 120, height: 20),
                  Spacer(),
                  _SkeletonBlock(width: 60, height: 14),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _SkeletonBlock(width: 130, height: 195, borderRadius: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NewsSkeleton extends StatelessWidget {
  const NewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant;
    final highlight = isDark ? AppColors.surfaceElevated : Colors.white;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _SkeletonBlock(width: double.infinity, height: 200, borderRadius: 14),
          ),
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _SkeletonBlock(width: 80, height: 60, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBlock(width: double.infinity, height: 14),
                        SizedBox(height: 6),
                        _SkeletonBlock(width: 160, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const _SkeletonBlock({required this.width, required this.height, this.borderRadius = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
