import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_providers.dart';
import '../../features/auth/application/auth_controller.dart';

/// Виджет для inline-показа изображений, лежащих за нашим API
/// (`/api/documents/:id/file`, `/api/documents/:id/thumbnail-file`).
/// Подставляет Bearer-токен в заголовки и склеивает абсолютный URL из
/// `env.apiBaseUrl + path`. Если [path] уже абсолютный (http/https) — не трогает.
class AppAuthImage extends ConsumerWidget {
  const AppAuthImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final storage = ref.watch(secureStorageProvider);
    final absoluteUrl = path.startsWith('http')
        ? path
        : '${env.apiBaseUrl}$path';
    return FutureBuilder<String?>(
      future: storage.readAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(width: width, height: height);
        }
        final token = snapshot.data;
        return Image.network(
          absoluteUrl,
          fit: fit,
          width: width,
          height: height,
          headers: token == null || token.isEmpty
              ? const {}
              : {'Authorization': 'Bearer $token'},
          errorBuilder: errorBuilder ?? (_, __, ___) => const SizedBox.shrink(),
        );
      },
    );
  }
}
