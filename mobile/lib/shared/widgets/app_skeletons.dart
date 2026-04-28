import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Набор skeleton-виджетов, которые передаются в
/// `AppLoadingState(skeleton:...)`. Skeletonizer в AppLoadingState
/// накладывает shimmer-эффект.

/// Скелет для списочных экранов (ProjectsScreen, StagesScreen, etc.).
/// Рисует 6 плейсхолдер-карточек одинаковой высоты.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    this.itemHeight = 88,
    this.itemCount = 6,
    super.key,
  });

  final double itemHeight;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.x16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x8),
      itemBuilder: (_, __) => _SkeletonCard(height: itemHeight),
    );
  }
}

/// Скелет для чат-списка — avatar + 2 строки.
class AppChatListSkeleton extends StatelessWidget {
  const AppChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
      itemCount: 8,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.n100),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x12,
        ),
        child: Row(
          children: [
            _SkeletonCircle(size: 44),
            SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: 160, height: 14),
                  SizedBox(height: 6),
                  _SkeletonLine(width: 240, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Скелет для детального экрана — hero + 4 секции.
class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: const [
        _SkeletonCard(height: 120),
        SizedBox(height: AppSpacing.x12),
        _SkeletonCard(height: 72),
        SizedBox(height: AppSpacing.x12),
        _SkeletonCard(height: 72),
        SizedBox(height: AppSpacing.x12),
        _SkeletonCard(height: 160),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
    );
  }
}

/// Универсальная плашка-плейсхолдер для inline-skeleton (Login loading,
/// Profile loading и т.п.). Серый прямоугольник с радиусом — `Skeletonizer`
/// сверху превращает в shimmer.
class AppSkeletonRow extends StatelessWidget {
  const AppSkeletonRow({
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.n100,
        shape: BoxShape.circle,
      ),
    );
  }
}
