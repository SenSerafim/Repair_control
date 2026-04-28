import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Плитка nav-grid консоли (s-console-* в Cluster B).
class AppNavTile extends StatelessWidget {
  const AppNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.n700,
    this.badge,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  /// Опциональный счётчик (например, непрочитанные уведомления / задачи).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        onTap: onTap,
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.n100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (badge != null && badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.redDot,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.n0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Адаптивная сетка nav-плиток консоли.
///
/// Дизайн: 2 колонки + поддержка `wide`-плиток на всю ширину (документы).
class AppNavTileGrid extends StatelessWidget {
  const AppNavTileGrid({required this.tiles, super.key});

  final List<AppNavTileSpec> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var i = 0;
    while (i < tiles.length) {
      final t = tiles[i];
      if (t.wide) {
        rows.add(_buildTile(t));
        i += 1;
      } else {
        final next = i + 1 < tiles.length ? tiles[i + 1] : null;
        if (next == null || next.wide) {
          rows.add(
            Row(
              children: [
                Expanded(child: _buildTile(t)),
                const SizedBox(width: AppSpacing.x8),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
          i += 1;
        } else {
          rows.add(
            Row(
              children: [
                Expanded(child: _buildTile(t)),
                const SizedBox(width: AppSpacing.x8),
                Expanded(child: _buildTile(next)),
              ],
            ),
          );
          i += 2;
        }
      }
      if (i < tiles.length) {
        rows.add(const SizedBox(height: AppSpacing.x8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildTile(AppNavTileSpec t) => AppNavTile(
        icon: t.icon,
        label: t.label,
        onTap: t.onTap,
        iconColor: t.iconColor,
        badge: t.badge,
      );
}

/// Спецификация одной плитки для AppNavTileGrid.
class AppNavTileSpec {
  const AppNavTileSpec({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.n700,
    this.badge,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final int? badge;

  /// `true` — плитка занимает полную ширину (одна в строке).
  final bool wide;
}
