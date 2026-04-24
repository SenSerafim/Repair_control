import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../domain/user_profile.dart';

/// Brandирующий hero-блок (prof-hero из кластера A).
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    required this.profile,
    this.onEdit,
    super.key,
  });

  final UserProfile profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x20,
        AppSpacing.x24,
        AppSpacing.x20,
        AppSpacing.x24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r24),
        boxShadow: AppShadows.shBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(profile: profile),
              const SizedBox(width: AppSpacing.x14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName.isEmpty
                          ? 'Без имени'
                          : profile.fullName,
                      style: AppTextStyles.h1.copyWith(color: AppColors.n0),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.phone,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.brandLight),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.n0,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (profile.activeRole != null) ...[
            const SizedBox(height: AppSpacing.x16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: AppSpacing.x6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteGhost,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Активная роль · ${profile.activeRole!.displayName}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.n0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.whiteGhost,
        shape: BoxShape.circle,
        image: url == null
            ? null
            : DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
      ),
      child: url != null
          ? null
          : Text(
              profile.initials.isEmpty ? '?' : profile.initials,
              style: AppTextStyles.h1.copyWith(color: AppColors.n0),
            ),
    );
  }
}
