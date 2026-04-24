import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/legal_controller.dart';
import '../data/auth_repository.dart';
import '../domain/legal_document.dart';

/// Модал с обязательным принятием legal-документа.
/// Вызывается из AuthGate сразу после логина, если есть pendingKinds.
class LegalAcceptanceModal extends ConsumerStatefulWidget {
  const LegalAcceptanceModal({required this.kind, super.key});

  final LegalKind kind;

  @override
  ConsumerState<LegalAcceptanceModal> createState() =>
      _LegalAcceptanceModalState();
}

class _LegalAcceptanceModalState
    extends ConsumerState<LegalAcceptanceModal> {
  LegalDocument? _doc;
  bool _loading = true;
  bool _error = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final doc = await ref.read(authRepositoryProvider).legalGet(widget.kind);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _submitting = true);
    await ref.read(legalControllerProvider.notifier).accept(widget.kind);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.n50,
      child: AppScaffold(
        title: widget.kind.title,
        backgroundColor: AppColors.n50,
        leading: const SizedBox.shrink(),
        body: Column(
          children: [
            Expanded(child: _buildContent()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: AppButton(
                label: 'Принимаю',
                onPressed: _doc == null ? null : _accept,
                isLoading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const AppLoadingState();
    if (_error) {
      return AppErrorState(
        title: 'Не удалось загрузить документ',
        onRetry: _load,
      );
    }
    final doc = _doc;
    if (doc == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.title, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Версия ${doc.version}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(doc.bodyMd, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

/// Утилита — показывает модалы для всех pending legal-kinds по очереди.
Future<void> showPendingLegalAcceptance(
  BuildContext context,
  WidgetRef ref,
) async {
  await ref.read(legalControllerProvider.notifier).refresh();
  for (final kind in ref.read(legalControllerProvider).pendingKinds) {
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LegalAcceptanceModal(kind: kind),
      ),
    );
  }
}
