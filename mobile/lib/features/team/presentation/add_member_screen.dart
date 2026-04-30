import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/phone_formatter.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../data/team_repository.dart';

/// s-add-member — full-screen экран поиска подрядчика по телефону.
///
/// Дизайн `Кластер A` (s-add-member): info-banner с проектом → search-bar
/// (телефон) → кнопка «Найти» → недавно добавленные.
class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _phone = TextEditingController();
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_phone.text.trim().isEmpty) {
      setState(() => _error = 'Введите номер телефона');
      return;
    }
    if (!isValidPhoneE164(_phone.text)) {
      setState(() => _error = 'Введите 10 цифр номера');
      return;
    }
    final raw = phoneToE164(_phone.text);
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final user = await ref.read(teamRepositoryProvider).searchUser(
            projectId: widget.projectId,
            phone: raw,
          );
      if (!mounted) return;
      setState(() => _searching = false);
      if (user != null) {
        context.push(
          AppRoutes.projectMemberFoundWith(widget.projectId),
          extra: MemberFoundArgs(
            userId: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            phone: user.phone,
          ),
        );
      } else {
        context.push(
          AppRoutes.projectMemberNotFoundWith(widget.projectId),
          extra: raw,
        );
      }
    } on TeamException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync =
        ref.watch(projectControllerProvider(widget.projectId));
    final projectTitle = projectAsync.maybeWhen(
      data: (p) => p.title,
      orElse: () => '...',
    );
    final teamState = ref.watch(teamControllerProvider(widget.projectId));
    final recentMembers = teamState.maybeWhen<List<Membership>>(
      data: (s) =>
          s.members.where((m) => m.user != null).take(5).toList(),
      orElse: () => const <Membership>[],
    );

    return AppScaffold(
      showBack: true,
      title: 'Добавить участника',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _ProjectBanner(title: projectTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x12,
            ),
            child: AppInput(
              controller: _phone,
              placeholder: '(000) 000-00-00',
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              prefixIcon: const RuPhonePrefix(),
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: AppButton(
                  label: 'Найти',
                  size: AppButtonSize.sm,
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  isLoading: _searching,
                  onPressed: _search,
                ),
              ),
            ),
          ),
          if (recentMembers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'НЕДАВНО ДОБАВЛЕННЫЕ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                itemCount: recentMembers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.x10),
                itemBuilder: (_, i) {
                  final m = recentMembers[i];
                  return _MemberCard(
                    initials: '${_initial(m.user!.firstName)}'
                        '${_initial(m.user!.lastName)}',
                    name: '${m.user!.firstName} ${m.user!.lastName}'.trim(),
                    role: m.role.displayName,
                    palette: i.isEven
                        ? AvatarPalette.blue
                        : AvatarPalette.green,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initial(String s) =>
      s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
}

class _ProjectBanner extends StatelessWidget {
  const _ProjectBanner({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x10,
      ),
      color: AppColors.brandLight,
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.house, size: 14, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Проект: $title',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.initials,
    required this.name,
    required this.role,
    required this.palette,
  });

  final String initials;
  final String name;
  final String role;
  final AvatarPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          AppAvatar(
            seed: initials,
            name: name,
            size: 40,
            palette: palette,
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
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

/// Аргумент для MemberFoundScreen — передаётся через `extra` go_router.
class MemberFoundArgs {
  const MemberFoundArgs({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
}
