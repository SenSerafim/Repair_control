import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';

/// e-mat-edit-pos: фактическая цена (per unit) + опц. комментарий + photo
/// чека. Бекенд уже принимает pricePerUnit; qty/comment/photo сохраняются на
/// клиенте. Сохранение → POST /materials/:id/items/:itemId/bought.
class EditPurchasedItemScreen extends ConsumerStatefulWidget {
  const EditPurchasedItemScreen({
    required this.projectId,
    required this.requestId,
    required this.itemId,
    super.key,
  });

  final String projectId;
  final String requestId;
  final String itemId;

  @override
  ConsumerState<EditPurchasedItemScreen> createState() =>
      _EditPurchasedItemScreenState();
}

class _EditPurchasedItemScreenState
    extends ConsumerState<EditPurchasedItemScreen> {
  final _priceCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _busy = false;
  String? _photoKey;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(materialsControllerProvider(widget.projectId));
    final request = async.value
        ?.cast<MaterialRequest?>()
        .firstWhere((r) => r?.id == widget.requestId, orElse: () => null);
    final item = request?.items
        .cast<MaterialItem?>()
        .firstWhere((i) => i?.id == widget.itemId, orElse: () => null);

    if (item == null) {
      return const AppScaffold(
        showBack: true,
        title: 'Ред. позицию',
        body: AppEmptyState(
          title: 'Позиция не найдена',
          icon: Icons.error_outline_rounded,
        ),
      );
    }

    // Однократная инициализация контроллера ценой.
    if (_priceCtrl.text.isEmpty && item.pricePerUnit != null) {
      MoneyInput.setFromKopecks(_priceCtrl, item.pricePerUnit!);
    }

    return AppScaffold(
      showBack: true,
      title: 'Ред. позицию',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x20),
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.h2.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.x16),
                _Field(
                  label: 'Фактически куплено',
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: AppColors.n50,
                      border:
                          Border.all(color: AppColors.brand, width: 1.5),
                      borderRadius:
                          BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Text(
                      '${_fmtQty(item.qty)} ${item.unit ?? ''}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.n900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x14),
                _Field(
                  label: 'Фактическая цена за ед., ₽',
                  child: MoneyInput(
                    controller: _priceCtrl,
                    label: 'Цена за единицу',
                  ),
                ),
                const SizedBox(height: AppSpacing.x14),
                _Field(
                  label: 'Комментарий',
                  child: TextField(
                    controller: _commentCtrl,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Купил в…, цена чуть выше',
                      filled: true,
                      fillColor: AppColors.n50,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.r12),
                        borderSide: const BorderSide(
                          color: AppColors.n200,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x14),
                _Field(
                  label: 'Фото чека',
                  child: AppPhotoGrid(
                    imageUrls: _photoKey == null ? const [] : [_photoKey!],
                    onAdd: () async {
                      // Photo upload-flow подключим позже — placeholder.
                      AppToast.show(
                        context,
                        message: 'Прикрепить фото — в следующей итерации',
                      );
                    },
                    onDeletePhoto: (_) => setState(() => _photoKey = null),
                  ),
                ),
                const SizedBox(height: AppSpacing.x12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.boughtAt == null
                              ? 'Дата покупки зафиксируется автоматически'
                              : 'Дата покупки: ${DateFormat('d MMM, HH:mm', 'ru').format(item.boughtAt!)} (неизменяемая)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x12,
              AppSpacing.x16,
              AppSpacing.x16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.n0,
              border: Border(top: BorderSide(color: AppColors.n200)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: 'Сохранить',
                onPressed: _busy ? null : () => _save(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(MaterialItem item) async {
    final price = MoneyInput.readKopecks(_priceCtrl);
    if (price == null || price <= 0) {
      AppToast.show(
        context,
        message: 'Укажите цену больше 0',
        kind: AppToastKind.error,
      );
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(materialsControllerProvider(widget.projectId).notifier)
        .markBought(
          requestId: widget.requestId,
          itemId: item.id,
          pricePerUnit: price,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String _fmtQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.n500,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
