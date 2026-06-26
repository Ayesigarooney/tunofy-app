import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/radio_station.dart';
import '../../../data/services/channel_refresh_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/tunofy_widgets.dart';

class TvScreen extends ConsumerWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(tvCategoriesProvider).valueOrNull ?? ['All'];
    final selectedCategory = ref.watch(selectedTvCategoryProvider);
    final channelsAsync = ref.watch(filteredTvChannelsProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);

    final slivers = <Widget>[
      SliverAppBar(
        floating: true,
        snap: true,
        title: const TunofyTitle(
          subtitle: 'TV',
          subtitleColor: AppColors.accentGreen,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearch(context, ref),
          ),
        ],
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 8)),

      SliverPersistentHeader(
        pinned: true,
        delegate: _TvCategoryHeader(
          categories: categories,
          selected: selectedCategory,
          onSelected: (cat) =>
              ref.read(selectedTvCategoryProvider.notifier).state = cat,
        ),
      ),
    ];

    channelsAsync.when(
      loading: () => slivers.add(const SliverFillRemaining(
        child: TvSkeleton(),
      )),
      error: (e, _) => slivers.add(SliverFillRemaining(
        child: TunoErrorWidget(
          message: 'Could not load channels.\nPull down to retry.',
          onRetry: () => ref.invalidate(tvChannelsProvider),
        ),
      )),
      data: (channels) {
        if (channels.any((c) => favoriteIds.contains(c.id))) {
          slivers.add(SliverToBoxAdapter(
            child: _TvFavoritesRow(channels: channels),
          ));
        }
        slivers.add(SliverToBoxAdapter(child: _TvSortRow()));
        slivers.add(_SliverTvGrid(channels: channels, favoriteIds: favoriteIds, ref: ref));
      },
    );

    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 16)));

    return Scaffold(
      body: CustomScrollView(slivers: slivers),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _TvSearchDelegate(ref),
    );
  }
}

// ─── TV Search Delegate ───────────────────────────────────────────────────────

class _TvSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _TvSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final channelsAsync = ref.watch(tvChannelsProvider);
    return channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load channels')),
      data: (all) {
        final filtered = query.isEmpty
            ? all
            : all
                .where((c) =>
                    c.name.toLowerCase().contains(query.toLowerCase()) ||
                    c.category.toLowerCase().contains(query.toLowerCase()) ||
                    (c.country?.toLowerCase().contains(query.toLowerCase()) ?? false))
                .toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No channels found for "$query"'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final c = filtered[i];
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    c.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              title: Text(c.name),
              subtitle: Text('${c.category}${c.country != null && c.country!.isNotEmpty ? ' • ${c.country}' : ''}'),
              trailing: IconButton(
                icon: Icon(
                  ref.watch(favoriteIdsProvider).contains(c.id)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: ref.watch(favoriteIdsProvider).contains(c.id)
                      ? AppColors.accentOrange
                      : null,
                ),
                onPressed: () => ref.read(favoriteIdsProvider.notifier).toggle(c.id, 'tv'),
              ),
              onTap: () {
                close(context, c.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TvPlayerScreen(channel: c),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Custom TV Hero ───────────────────────────────────────────────────────────

// ─── TV Channel Card ──────────────────────────────────────────────────────────

class _TvChannelCard extends StatelessWidget {
  final TvChannel channel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _TvChannelCard({
    required this.channel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Logo placeholder
            Center(
              child: Text(
                channel.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 8,
              left: 10,
              right: 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channel.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.country != null && channel.country!.isNotEmpty)
                    Text(
                      channel.country!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Favorite button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: isFavorite ? AppColors.accentOrange : Colors.white.withValues(alpha: 0.6),
                ),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ),
            // Play overlay
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TV Favorites Row ─────────────────────────────────────────────────────────

class _TvFavoritesRow extends ConsumerWidget {
  final List<TvChannel> channels;

  const _TvFavoritesRow({required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);
    final favorites = channels.where((c) => ids.contains(c.id)).toList();
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'My Favorites'),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = favorites[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _TvPlayerScreen(channel: c),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          c.name[0],
                          style: const TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 54,
                      child: Text(
                        c.name,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── TV Sort Row ──────────────────────────────────────────────────────────────

class _TvSortRow extends ConsumerWidget {
  const _TvSortRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(tvSortProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('Sort: ', style: TextStyle(fontSize: 12)),
          _SortChip('Default', sort, ref),
          const SizedBox(width: 6),
          _SortChip('Name', sort, ref),
          const SizedBox(width: 6),
          _SortChip('Country', sort, ref),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String value;
  final String current;
  final WidgetRef ref;

  const _SortChip(this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => ref.read(tvSortProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.accentGreen : null,
          ),
        ),
      ),
    );
  }
}

// ─── TV Channel Grid (virtualized via SliverGrid) ─────────────────────────────

class _SliverTvGrid extends ConsumerWidget {
  final List<TvChannel> channels;
  final Set<String> favoriteIds;
  final WidgetRef ref;

  const _SliverTvGrid({
    required this.channels,
    required this.favoriteIds,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ch = channels[index];
            return _TvChannelCard(
              channel: ch,
              isFavorite: favoriteIds.contains(ch.id),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TvPlayerScreen(channel: ch),
                  ),
                );
              },
              onFavoriteTap: () =>
                  ref.read(favoriteIdsProvider.notifier).toggle(ch.id, 'tv'),
            );
          },
          childCount: channels.length,
        ),
      ),
    );
  }
}

// ─── TV Player Screen ─────────────────────────────────────────────────────────

class _TvPlayerScreen extends ConsumerStatefulWidget {
  final TvChannel channel;

  const _TvPlayerScreen({required this.channel});

  @override
  ConsumerState<_TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends ConsumerState<_TvPlayerScreen> {
  Player? _mediaKitPlayer;
  VideoController? _videoController;
  bool _isBuffering = false;
  bool _loading = true;
  String? _errorMessage;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  Future<void> _resolveAndPlay() async {
    final settings = ref.read(settingsRepositoryProvider);
    final channelId = widget.channel.id;

    final storedUrl = settings.getChannelUrl(channelId);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      _resolvedUrl = storedUrl;
      _initMediaKit();
      return;
    }

    final refreshPage = settings.getChannelRefreshPage(channelId);
    if (refreshPage != null && refreshPage.isNotEmpty) {
      try {
        final freshUrl = await ChannelRefreshService().refreshFromPage(refreshPage);
        if (freshUrl != null && mounted) {
          _resolvedUrl = freshUrl;
          await settings.setChannelUrl(channelId, freshUrl);
          _initMediaKit();
          return;
        }
      } catch (_) {}
    }

    _resolvedUrl = widget.channel.primaryUrl;
    _initMediaKit();
  }

  void _initMediaKit() {
    if (!mounted) return;
    final player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _mediaKitPlayer = player;
    _videoController = VideoController(player);

    player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });

    player.stream.error.listen((err) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _errorMessage = 'Stream error — try another channel.';
          _loading = false;
        });
      }
    });

    final url = _resolvedUrl ?? widget.channel.primaryUrl;
    final media = url.contains('uvotv-aniview')
        ? Media(url, httpHeaders: {'Referer': 'https://uvotv.com'})
        : Media(url);

    player.open(media).then((_) {
      // Seek to live edge
      player.seek(const Duration(days: 365));
      if (mounted) setState(() => _loading = false);
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not open stream.';
        });
      }
    });
  }

  void _jumpToLive() => _mediaKitPlayer?.seek(const Duration(days: 365));

  @override
  void dispose() {
    _mediaKitPlayer?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.channel.name,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.fiber_manual_record_rounded, color: AppColors.liveRed),
            tooltip: 'Jump to live',
            onPressed: _jumpToLive,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading && _errorMessage == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            )
          else if (_errorMessage != null)
            Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.white54)),
            )
          else if (_videoController != null)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(controller: _videoController!),
                ),
                const Expanded(child: _TvPlayerInfo()),
              ],
            ),
          if (_isBuffering && !_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            ),
        ],
      ),
    );
  }
}

class _TvPlayerInfo extends StatelessWidget {
  const _TvPlayerInfo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Now Playing',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.accentOrange)),
          const SizedBox(height: 4),
          Text('Live Broadcast',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Category persistent header ───────────────────────────────────────────────

class _TvCategoryHeader extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  _TvCategoryHeader({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CategoryChipBar(
        categories: categories,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  double get maxExtent => 52;
  @override
  double get minExtent => 52;
  @override
  bool shouldRebuild(_TvCategoryHeader old) =>
      old.selected != selected || old.categories != categories;
}
