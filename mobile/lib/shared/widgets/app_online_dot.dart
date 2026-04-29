import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Online/last-seen индикатор для team-members в `f-team-*`.
///
/// Online: 6px зелёный круг + текст «Online» (10/600/`greenDark`).
/// Offline: только время «2ч» / «10 фев» / «вчера» (10/600/n400).
class AppOnlineDot extends StatelessWidget {
  const AppOnlineDot.online({super.key})
      : online = true,
        lastSeenLabel = null;

  const AppOnlineDot.lastSeen({required String label, super.key})
      : online = false,
        lastSeenLabel = label;

  final bool online;
  final String? lastSeenLabel;

  @override
  Widget build(BuildContext context) {
    if (online) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.greenDot,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 6, height: 6),
          ),
          SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.greenDark,
            ),
          ),
        ],
      );
    }
    return Text(
      lastSeenLabel ?? '',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.n400,
      ),
    );
  }
}
