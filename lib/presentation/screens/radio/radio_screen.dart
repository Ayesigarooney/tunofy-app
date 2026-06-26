import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player_state.dart';
import '../../../data/models/radio_station.dart';
import '../../providers/app_providers.dart';
import '../../widgets/tunofy_widgets.dart';

class RadioScreen extends ConsumerWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(radioCategoriesProvider).valueOrNull ?? ['All'];
    final selectedCategory = ref.watch(selectedRadioCategoryProvider);
    final stationsAsync = ref.watch(filteredRadioStationsProvider);
    final playerState = ref.watch(playerStateProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);

    final slivers = <Widget>[
      SliverAppBar(
        floating: true,
        snap: true,
        title: const TunofyTitle(subtitle: 'RADIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearch(context, ref),
          ),
        ],
      ),
    ];

    stationsAsync.when(
      loading: () => slivers.add(const SliverFillRemaining(
        child: RadioSkeleton(),
      )),
      error: (e, _) => slivers.add(SliverFillRemaining(
        child: TunoErrorWidget(
          message: 'Could not load stations.\nPull down to retry.',
          onRetry: () => ref.invalidate(radioStationsProvider),
        ),
      )),
      data: (stations) {
        final allStations = ref.watch(radioStationsProvider).valueOrNull ?? stations;
        if (allStations.isNotEmpty) {
          if (allStations.any((s) => favoriteIds.contains(s.id))) {
            slivers.add(SliverToBoxAdapter(
              child: _FavoritesRow(allStations: allStations),
            ));
          }
          slivers.add(SliverToBoxAdapter(
            child: _RecentRow(allStations: allStations),
          ));
          slivers.add(SliverToBoxAdapter(child: _RadioSortRow()));
          slivers.add(SliverToBoxAdapter(
            child: _CategoryHeader(
              categories: categories,
              selected: selectedCategory,
              onSelected: (cat) =>
                  ref.read(selectedRadioCategoryProvider.notifier).state = cat,
            ),
          ));
          slivers.add(_SliverStationList(
            stations: stations,
            playerState: playerState,
            favoriteIds: favoriteIds,
            ref: ref,
          ));
        }
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
      delegate: _RadioSearchDelegate(ref),
    );
  }
}

class _FavoritesRow extends ConsumerWidget {
  final List<RadioStation> allStations;

  const _FavoritesRow({required this.allStations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);
    final favorites = allStations.where((s) => ids.contains(s.id)).toList();

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
              final s = favorites[i];
              return GestureDetector(
                onTap: () => ref.read(playerStateProvider.notifier).playRadio(s),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.name[0],
                          style: const TextStyle(
                            color: AppColors.accentOrange,
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
                        s.name,
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

class _RecentRow extends ConsumerWidget {
  final List<RadioStation> allStations;

  const _RecentRow({required this.allStations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favRepo = ref.watch(favoritesRepositoryProvider);
    final recentIds = favRepo.getRecentIds(type: 'radio').take(6).toList();
    final recentStations =
        recentIds.map((id) => allStations.where((s) => s.id == id).firstOrNull).whereType<RadioStation>().toList();

    if (recentStations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Recently Played')),
              TextButton.icon(
                onPressed: () async {
                  await favRepo.clearRecent(type: 'radio');
                  ref.invalidate(radioStationsProvider);
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recentStations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = recentStations[i];
              return GestureDetector(
                onTap: () => ref.read(playerStateProvider.notifier).playRadio(s),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          s.name[0],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                        s.name,
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

class _RadioSortRow extends ConsumerWidget {
  const _RadioSortRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(radioSortProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('Sort: ', style: TextStyle(fontSize: 12)),
          _RadioSortChip('Default', sort, ref),
          const SizedBox(width: 6),
          _RadioSortChip('Name', sort, ref),
          const SizedBox(width: 6),
          _RadioSortChip('Country', sort, ref),
        ],
      ),
    );
  }
}

class _RadioSortChip extends StatelessWidget {
  final String value;
  final String current;
  final WidgetRef ref;

  const _RadioSortChip(this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => ref.read(radioSortProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentOrange.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.accentOrange : null,
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryHeader({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CategoryChipBar(
        categories: categories,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }
}

class _SliverStationList extends StatelessWidget {
  final List<RadioStation> stations;
  final TunoPlayerState playerState;
  final Set<String> favoriteIds;
  final WidgetRef ref;

  const _SliverStationList({
    required this.stations,
    required this.playerState,
    required this.favoriteIds,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final station = stations[index];
          final isPlaying = playerState.currentRadioStation?.id == station.id;
          return StationCard(
            id: station.id,
            name: station.name,
            logoUrl: station.logoUrl,
            subtitle: '${station.category} • ${station.country ?? ""}',
            isPlaying: isPlaying,
            isFavorite: favoriteIds.contains(station.id),
            onTap: () => ref.read(playerStateProvider.notifier).playRadio(station),
            onFavoriteTap: () =>
                ref.read(favoriteIdsProvider.notifier).toggle(station.id, 'radio'),
          );
        },
        childCount: stations.length,
      ),
    );
  }
}

class _RadioSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _RadioSearchDelegate(this.ref);

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
    final stationsAsync = ref.watch(radioStationsProvider);
    return stationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load stations')),
      data: (allStations) {
        final filtered = query.isEmpty
            ? allStations
            : allStations
                .where((s) =>
                    s.name.toLowerCase().contains(query.toLowerCase()) ||
                    (s.category.toLowerCase().contains(query.toLowerCase())))
                .toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No stations found for "$query"'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final s = filtered[i];
            return StationCard(
              id: s.id,
              name: s.name,
              logoUrl: s.logoUrl,
              subtitle: s.category,
              isPlaying: ref.watch(playerStateProvider).currentRadioStation?.id == s.id,
              isFavorite: ref.watch(favoriteIdsProvider).contains(s.id),
              onTap: () {
                ref.read(playerStateProvider.notifier).playRadio(s);
                close(context, s.id);
              },
              onFavoriteTap: () =>
                  ref.read(favoriteIdsProvider.notifier).toggle(s.id, 'radio'),
            );
          },
        );
      },
    );
  }
}
