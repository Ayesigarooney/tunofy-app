// lib/presentation/screens/news/news_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/share_utils.dart';
import '../../../data/models/news_article.dart';
import '../../providers/app_providers.dart';
import '../../widgets/tunofy_widgets.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              children: [
                Text('Tuno',
                    style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                Text('fy',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEWS',
                    style: TextStyle(
                      color: Colors.blue,
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
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(newsProvider),
              ),
            ],
          ),

          // Breaking header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _BreakingHeader(),
            ),
          ),

          newsAsync.when(
            loading: () => const SliverToBoxAdapter(child: ShimmerList()),
            error: (e, _) => SliverFillRemaining(
              child: TunoErrorWidget(
                message: 'Could not load news.\nCheck your internet connection.',
                onRetry: () => ref.invalidate(newsProvider),
              ),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return const SliverFillRemaining(
                  child: TunoErrorWidget(message: 'No articles found.'),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0 && articles.isNotEmpty) {
                      // Featured article at top
                      return _FeaturedArticleCard(
                        article: articles[0],
                        onTap: () => _openArticle(context, articles[0]),
                      );
                    }
                    final article = articles[index];
                    return _ArticleCard(
                      article: article,
                      onTap: () => _openArticle(context, article),
                    );
                  },
                  childCount: articles.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  void _openArticle(BuildContext context, NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ArticleReaderScreen(article: article)),
    );
  }
}

class _BreakingHeader extends StatelessWidget {
  const _BreakingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.liveRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.liveRed.withOpacity(0.3)),
          ),
          child: const Text(
            'BREAKING NEWS',
            style: TextStyle(
              color: AppColors.liveRed,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Uganda & East Africa',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _FeaturedArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Icon(Icons.newspaper_rounded, size: 40),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (article.source?.name ?? 'News').toUpperCase(),
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (article.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        article.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      article.formattedDate,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (article.source?.name ?? 'News').toUpperCase(),
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.formattedDate,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.newspaper_rounded, size: 24),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Article Reader ───────────────────────────────────────────────────────────

class _ArticleReaderScreen extends StatelessWidget {
  final NewsArticle article;

  const _ArticleReaderScreen({required this.article});

  void _openInAppWebView(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ArticleWebViewScreen(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.source?.name ?? 'Article'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareUtils.shareNewsArticle(
              article.title,
              article.url,
              article.source?.name,
            ),
          ),
          if (article.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              onPressed: () => _openInAppWebView(context, article.url!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (article.source != null)
              Text(
                article.source!.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            const SizedBox(height: 8),

            Text(article.title,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),

            Row(
              children: [
                if (article.author != null)
                  Text('By ${article.author}',
                      style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(article.formattedDate,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 20),

            if (article.description != null) ...[
              Text(
                article.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              article.content?.replaceAll(RegExp(r'\[\+\d+ chars\]'), '') ??
                  'Full article content not available in preview.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.65,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.82),
              ),
            ),

            const SizedBox(height: 24),
            if (article.url != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openInAppWebView(context, article.url!),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: const Text('Read Full Article'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentOrange,
                    side: const BorderSide(color: AppColors.accentOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ArticleWebViewScreen extends StatefulWidget {
  final String url;

  const _ArticleWebViewScreen({required this.url});

  @override
  State<_ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<_ArticleWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareUtils.shareNewsArticle(
              widget.url,
              widget.url,
              null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in external browser',
            onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
