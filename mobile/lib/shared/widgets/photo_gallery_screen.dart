import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Full-screen swipable gallery — photo_view + PageView.
/// Передаётся список URL. Показывает номер страницы + кнопку «назад».
class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({
    required this.urls,
    this.initialIndex = 0,
    this.heroTagPrefix = 'photo',
    super.key,
  });

  final List<String> urls;
  final int initialIndex;
  final String heroTagPrefix;

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late int _index = widget.initialIndex;
  late final _pageCtrl = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
            builder: (context, index) {
              final url = widget.urls[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(url),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: '${widget.heroTagPrefix}-$index',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
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
