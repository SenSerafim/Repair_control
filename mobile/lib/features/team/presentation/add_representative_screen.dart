import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/phone_formatter.dart';
import '../data/team_repository.dart';

/// s-add-representative — поиск представителя по телефону + purple-banner.
class AddRepresentativeScreen extends ConsumerStatefulWidget {
  const AddRepresentativeScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<AddRepresentativeScreen> createState() =>
      _AddRepresentativeScreenState();
}

class _AddRepresentativeScreenState
    extends ConsumerState<AddRepresentativeScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = phoneToE164(_phone.text);
    if (!isValidPhoneE164(raw)) {
      setState(() => _error = 'Введите корректный номер');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(teamRepositoryProvider)
          .searchUser(projectId: widget.projectId, phone: raw);
      if (!mounted) return;
      setState(() => _busy = false);
      if (user != null) {
        context.push(
          AppRoutes.projectRepRightsWith(widget.projectId),
          extra: user,
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
        _busy = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Добавить представителя',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Purple banner.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x10,
            ),
            color: AppColors.purpleBg,
            child: Row(
              children: [
                Icon(
                  PhosphorIconsFill.usersThree,
                  size: 14,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Представитель получит настраиваемые права',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: AppInput(
              controller: _phone,
              placeholder: 'Номер телефона представителя',
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: AppColors.n400,
                ),
              ),
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: _HintBox(
              text: 'После добавления вы сможете настроить права '
                  'представителя: просмотр бюджета, принятие работ '
                  'и другие.',
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
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
                  isLoading: _busy,
                  onPressed: _search,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.info,
            size: 16,
            color: AppColors.brand,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
