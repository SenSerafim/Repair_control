import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/tokens.dart';

/// Простой обёрточный виджет для воспроизведения видео из presigned URL.
/// Инициализирует VideoPlayerController и Chewie один раз; на dispose чистит.
class KnowledgeVideoPlayer extends StatefulWidget {
  const KnowledgeVideoPlayer({super.key, required this.url, this.aspectRatio});

  final String url;
  final double? aspectRatio;

  @override
  State<KnowledgeVideoPlayer> createState() => _KnowledgeVideoPlayerState();
}

class _KnowledgeVideoPlayerState extends State<KnowledgeVideoPlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await video.initialize();
      final ratio = widget.aspectRatio ?? video.value.aspectRatio;
      final chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: false,
        looping: false,
        aspectRatio: ratio == 0 ? 16 / 9 : ratio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.brand,
          handleColor: AppColors.brand,
          backgroundColor: AppColors.n200,
          bufferedColor: AppColors.n300,
        ),
      );
      if (!mounted) {
        unawaited(video.dispose());
        chewie.dispose();
        return;
      }
      setState(() {
        _video = video;
        _chewie = chewie;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _chewie == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Text(
          'Видео недоступно: ${_error ?? 'неизвестная ошибка'}',
          style: const TextStyle(color: AppColors.n500, fontSize: 13),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Chewie(controller: _chewie!),
    );
  }
}
