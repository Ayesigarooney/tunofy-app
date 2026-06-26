// lib/presentation/screens/movies/movies_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/movie.dart';
import '../../providers/app_providers.dart';
import '../../widgets/tunofy_widgets.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tuno',
                    style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                Text('fy',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MOVIES',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _showMovieSearch(context, ref),
              ),
            ],
          ),

          moviesAsync.when(
            loading: () => const SliverFillRemaining(
              child: MoviesSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: TunoErrorWidget(
                message: 'Could not load movies.\nCheck your TMDB API key.',
                onRetry: () => ref.invalidate(moviesProvider),
              ),
            ),
            data: (categories) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= categories.length) return const SizedBox(height: 24);
                  final cat = categories[index];
                  return _MovieCategorySection(category: cat);
                },
                childCount: categories.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMovieSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _MovieSearchDelegate(ref));
  }
}

class _MovieCategorySection extends StatelessWidget {
  final MovieCategory category;

  const _MovieCategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    if (category.movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: category.name),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: category.movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final movie = category.movies[i];
              return MoviePosterCard(
                title: movie.title,
                posterUrl: movie.fullPosterUrl,
                rating: movie.formattedRating,
                year: movie.year,
                onTap: () => _openMovieDetail(context, movie),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openMovieDetail(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _MovieDetailScreen(movie: movie)),
    );
  }
}

// ─── Movie Detail Screen ──────────────────────────────────────────────────────

class _MovieDetailScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const _MovieDetailScreen({required this.movie});

  @override
  ConsumerState<_MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<_MovieDetailScreen> {
  bool _loadingTrailer = false;

  Future<void> _playTrailer() async {
    setState(() => _loadingTrailer = true);
    try {
      final service = ref.read(tmdbServiceProvider);
      final key = await service.getMovieTrailerKey(widget.movie.id);
      if (!mounted) return;
      if (key != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _MovieTrailerScreen(
              movieTitle: widget.movie.title,
              videoId: key,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trailer available for this title.'),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load trailer.'),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTrailer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.movie.fullBackdropUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.movie.fullBackdropUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor,
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                widget.movie.title,
                style: theme.textTheme.displayMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.movie.year.isNotEmpty) ...[
                    Text(widget.movie.year, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                  ],
                  if (widget.movie.voteAverage != null) ...[
                    const Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 14),
                    const SizedBox(width: 3),
                    Text(widget.movie.formattedRating, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (widget.movie.overview != null && widget.movie.overview!.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Overview',
                    style: theme.textTheme.headlineSmall),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(widget.movie.overview!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.55,
                    )),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SizedBox(
                width: double.infinity,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingTrailer ? null : _playTrailer,
                  icon: _loadingTrailer
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_loadingTrailer ? 'Loading...' : 'Play Trailer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _MovieTrailerScreen extends StatelessWidget {
  final String movieTitle;
  final String videoId;

  const _MovieTrailerScreen({required this.movieTitle, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(movieTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, size: 80,
                  color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text(movieTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://www.youtube.com/watch?v=$videoId'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Watch on YouTube'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back',
                    style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Movie Search ─────────────────────────────────────────────────────────────

class _MovieSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _MovieSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for movies…'));
    }

    // Update search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movieSearchQueryProvider.notifier).state = query;
    });

    final results = ref.watch(movieSearchResultsProvider);
    return results.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange)),
      error: (_, __) => const Center(child: Text('Search failed')),
      data: (movies) {
        if (movies.isEmpty) return Center(child: Text('No results for "$query"'));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.65,
          ),
          itemCount: movies.length,
          itemBuilder: (context, i) {
            final movie = movies[i];
            return MoviePosterCard(
              title: movie.title,
              posterUrl: movie.fullPosterUrl,
              rating: movie.formattedRating,
              year: movie.year,
              onTap: () {
                close(context, movie.id.toString());
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _MovieDetailScreen(movie: movie),
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
