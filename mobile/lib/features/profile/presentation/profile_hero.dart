import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/system_role.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/user_profile.dart';

/// s-profile hero — тёмный градиент с avatar + ФИО + телефон + role-chip.
///
/// Дизайн `Кластер A` (s-profile): SafeArea-padding сверху, статус-бар
/// прозрачный с белыми иконками, аватар 80×80 в белой рамке 3px.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    required this.profile,
    this.onTapRole,
    super.key,
  });

  final UserProfile profile;

  /// Tap по role-chip — открывает RolesScreen.
  final VoidCallback? onTapRole;

  @override
  Widget build(BuildContext context) {
    final role = profile.activeRole;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppHeroHeader(
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.x16),
            _Avatar(profile: profile),
            const SizedBox(height: AppSpacing.x14),
            Text(
              profile.fullName.isEmpty ? 'Без имени' : profile.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.n0,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              profile.phone.isEmpty
                  ? '—'
                  : _formatPhone(profile.phone),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0x80FFFFFF),
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            if (role != null && role != SystemRole.admin)
              AppRoleChip(
                label: role.displayName,
                icon: _iconFor(role),
                onTap: onTapRole,
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(SystemRole r) => switch (r) {
        SystemRole.customer => PhosphorIconsFill.user,
        SystemRole.contractor => PhosphorIconsFill.wrench,
        SystemRole.master => PhosphorIconsFill.hardHat,
        SystemRole.representative => PhosphorIconsFill.usersThree,
        SystemRole.admin => PhosphorIconsFill.shieldStar,
      };

  static String _formatPhone(String e164) {
    if (!e164.startsWith('+')) return e164;
    final digits = e164.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('7')) return e164;
    final c = digits;
    return '+7 (${c.substring(1, 4)}) ${c.substring(4, 7)}-'
        '${c.substring(7, 9)}-${c.substring(9, 11)}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x4DFFFFFF), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AppAvatar(
          seed: profile.id.isEmpty ? profile.phone : profile.id,
          name: profile.fullName,
          imageUrl: profile.avatarUrl,
          size: 80,
          palette: AvatarPalette.blue,
        ),
      ),
    );
  }
}
