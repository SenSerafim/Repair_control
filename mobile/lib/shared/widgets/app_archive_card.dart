import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Карточка архивного проекта (s-archive).
///
/// Title + meta-line, под ними split-row из 2 кликабельных половин
/// «Восстановить» (синяя) / «Скачать ZIP» (серая).
class AppArchiveCard extends StatelessWidget {
  const AppArchiveCard({
    required this.title,
    required this.meta,
    required this.onRestore,
    required this.onDownload,
    super.key,
  });

  final String title;
  final String meta;
  final VoidCallback onRestore;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.n100),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onRestore,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Восстановить',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.n100),
              Expanded(
                child: InkWell(
                  onTap: onDownload,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Скачать ZIP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.n500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
