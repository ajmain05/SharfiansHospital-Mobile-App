import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:photo_view/photo_view.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _categoryFilter = '';

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(siteSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'gallery')),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) {
            if (settings.galleryImages.isEmpty) return _EmptyGallery();

            final categories = galleryCategoriesOf(settings.galleryImages);
            final filtered = _categoryFilter.isEmpty
                ? settings.galleryImages
                : settings.galleryImages
                    .where((img) => img.category.trim().toLowerCase() == _categoryFilter.toLowerCase())
                    .toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                    child: Center(
                      child: Lottie.asset(
                        'assets/animations/camera.json',
                        height: 180,
                        fit: BoxFit.contain,
                        frameRate: const FrameRate(30),
                      ),
                    ),
                  ),
                ),
                if (categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _CategoryChip(
                            label: t(ref, 'galleryAllCategories'),
                            selected: _categoryFilter.isEmpty,
                            onTap: () => setState(() => _categoryFilter = ''),
                          ),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _CategoryChip(
                                label: c,
                                selected: _categoryFilter.toLowerCase() == c.toLowerCase(),
                                onTap: () => setState(() => _categoryFilter = c),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (categories.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          t(ref, 'galleryNoPhotosInCategory'),
                          style: TextStyle(color: context.textMed),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _GalleryTile(
                          image: filtered[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _GalleryViewer(
                                images: filtered,
                                initialIndex: index,
                              ),
                            ),
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(siteSettingsProvider),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : context.cardFill2,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(color: context.borderFill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.textMed,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final GalleryImage image;
  final VoidCallback onTap;

  const _GalleryTile({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: image.url,
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: context.cardFill2),
                errorWidget: (_, _, _) => Container(
                  color: context.cardFill2,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.textMed,
                  ),
                ),
              ),
            ),
            if (image.title.isNotEmpty || image.caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(
                    image.title.isNotEmpty ? image.title : image.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const _GalleryViewer({required this.images, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_index];
    final caption = image.caption.isNotEmpty ? image.caption : image.title;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.images[i];
              return Hero(
                tag: item.url,
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(item.url),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
              );
            },
          ),
          if (caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: context.textMed,
              ),
              const SizedBox(height: 12),
              Text(
                t(ref, 'noGalleryImages'),
                style: TextStyle(color: context.textMed),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
