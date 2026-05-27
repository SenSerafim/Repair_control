import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/image_compress.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
import '../application/materials_controller.dart';
import '../data/materials_repository.dart';
import '../domain/material_request.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  const CreateMaterialScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateMaterialScreen> createState() =>
      _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends ConsumerState<CreateMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _comment = TextEditingController();
  MaterialRecipient _recipient = MaterialRecipient.foreman;

  /// `null` = общая заявка проекта (бэк допускает stageId=null, ТЗ §5.1).
  String? _stageId;
  final _items = <_ItemDraft>[_ItemDraft()];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _pickItemPhoto(_ItemDraft draft) async {
    // ТЗ NEWFIX §5.2: фото к позиции (упаковка/чек/образец). Mobile-flow —
    // image_picker → compressImage (1920/80, EXIF zero) → presign → S3 PUT.
    // itemId на этом этапе ещё не создан, поэтому fileKey уходит в backend
    // и сохраняется как MaterialItemPhoto при createRequest.
    if (draft.uploadingPhoto) return;
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось открыть галерею');
      }
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => draft.uploadingPhoto = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final compressed = compressImage(bytes);
      if (compressed == null) {
        if (mounted) setState(() => _error = 'Файл не похож на фото');
        return;
      }
      final repo = ref.read(materialsRepositoryProvider);
      final presigned = await repo.presignItemPhoto(
        mimeType: compressed.mimeType,
        sizeBytes: compressed.sizeBytes,
        originalName: picked.name,
      );
      await repo.uploadToStorage(
        presigned: presigned,
        bytes: compressed.bytes,
        mimeType: compressed.mimeType,
      );
      if (!mounted) return;
      setState(() {
        draft.photo = MaterialItemPhotoInput(
          fileKey: presigned.fileKey,
          mimeType: compressed.mimeType,
          sizeBytes: compressed.sizeBytes,
          exifCleared: true,
        );
      });
    } on MaterialsException catch (e) {
      if (mounted) setState(() => _error = 'Не удалось загрузить фото: ${e.failure.name}');
    } finally {
      if (mounted) setState(() => draft.uploadingPhoto = false);
    }
  }

  Future<void> _pickDueDate(_ItemDraft draft) async {
    final now = DateTime.now();
    final initial = draft.dueDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Срок поставки',
      cancelText: 'Отмена',
      confirmText: 'OK',
    );
    if (picked == null || !mounted) return;
    setState(() => draft.dueDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final items = <MaterialItemInput>[];
    for (final draft in _items) {
      final name = draft.name.text.trim();
      final qty = double.tryParse(draft.qty.text.replaceAll(',', '.'));
      if (name.isEmpty || qty == null || qty <= 0) {
        setState(() => _error = 'Заполните все позиции');
        return;
      }
      items.add(
        MaterialItemInput(
          name: name,
          qty: qty,
          unit: draft.unit.text.trim().isEmpty ? null : draft.unit.text.trim(),
          pricePerUnit: MoneyInput.readKopecks(draft.price),
          dueDate: draft.dueDate,
          photo: draft.photo,
        ),
      );
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(materialsControllerProvider(widget.projectId).notifier)
        .create(
          recipient: _recipient,
          title: _title.text.trim(),
          items: items,
          stageId: _stageId,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Заявка создана',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Заявка на материалы',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.x16),
            if (_error != null) ...[
              AppInlineError(message: _error!),
              const SizedBox(height: AppSpacing.x12),
            ],
            const Text('Кто покупает', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            Wrap(
              spacing: 8,
              children: [
                for (final r in MaterialRecipient.values)
                  ChoiceChip(
                    label: Text(r.displayName),
                    selected: _recipient == r,
                    onSelected: (_) => setState(() => _recipient = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Этап', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            _StagePicker(
              projectId: widget.projectId,
              selectedStageId: _stageId,
              onChanged: (id) => setState(() => _stageId = id),
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Название заявки', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              decoration: _dec('Например, «Электрика этап 3»'),
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Позиции', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.x8),
            for (var i = 0; i < _items.length; i++) ...[
              _ItemCard(
                draft: _items[i],
                index: i + 1,
                canRemove: _items.length > 1,
                onRemove: () => setState(() {
                  _items[i].dispose();
                  _items.removeAt(i);
                }),
                onPickDueDate: () => _pickDueDate(_items[i]),
                onPickPhoto: () => _pickItemPhoto(_items[i]),
                onRemovePhoto: () => setState(() => _items[i].photo = null),
              ),
              const SizedBox(height: AppSpacing.x10),
            ],
            AppButton(
              label: 'Добавить позицию',
              variant: AppButtonVariant.ghost,
              onPressed: () => setState(() => _items.add(_ItemDraft())),
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text(
              'Комментарий (опционально)',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _comment,
              maxLines: 3,
              maxLength: 2000,
              decoration: _dec('Детали, адрес магазина…'),
            ),
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: 'Создать заявку',
              isLoading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }
}

class _StagePicker extends ConsumerWidget {
  const _StagePicker({
    required this.projectId,
    required this.selectedStageId,
    required this.onChanged,
  });

  final String projectId;
  final String? selectedStageId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stagesControllerProvider(projectId));
    return async.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Text(
        'Не удалось загрузить этапы',
        style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
      ),
      data: (stages) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Общая заявка'),
            selected: selectedStageId == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final s in stages)
            ChoiceChip(
              label: Text(s.title),
              selected: selectedStageId == s.id,
              onSelected: (_) => onChanged(s.id),
            ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  final name = TextEditingController();
  final qty = TextEditingController();
  final unit = TextEditingController(text: 'шт');
  final price = TextEditingController();
  // ТЗ NEWFIX §5.5: срок поставки позиции — показывается на карточке заявки,
  // cron эмитит overdue если статус всё ещё open после dueDate.
  DateTime? dueDate;
  // ТЗ NEWFIX §5.2: фото к позиции. Поле fileKey валидно после успешного
  // presign+PUT — отправляем в createRequest, бекенд сохранит MaterialItemPhoto.
  MaterialItemPhotoInput? photo;
  bool uploadingPhoto = false;

  void dispose() {
    name.dispose();
    qty.dispose();
    unit.dispose();
    price.dispose();
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onPickDueDate,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final _ItemDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onPickDueDate;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.micro.copyWith(color: AppColors.brand),
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: TextFormField(
                  controller: draft.name,
                  decoration: _inlineDec('Название'),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: AppColors.n400),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: draft.qty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inlineDec('Кол-во'),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: TextFormField(
                  controller: draft.unit,
                  decoration: _inlineDec('Ед.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          MoneyInput(
            controller: draft.price,
            label: 'Цена за единицу (опционально)',
          ),
          const SizedBox(height: AppSpacing.x8),
          // ТЗ NEWFIX §5.5: срок поставки позиции.
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            onTap: onPickDueDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x12,
                vertical: AppSpacing.x10,
              ),
              decoration: BoxDecoration(
                color: AppColors.n0,
                border: Border.all(color: AppColors.n200, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: AppColors.n500,
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      draft.dueDate == null
                          ? 'Срок поставки (опционально)'
                          : 'Срок: ${DateFormat('d MMMM', 'ru').format(draft.dueDate!)}',
                      style: AppTextStyles.body.copyWith(
                        color: draft.dueDate == null
                            ? AppColors.n400
                            : AppColors.n900,
                      ),
                    ),
                  ),
                  if (draft.dueDate != null)
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.n400,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          // ТЗ NEWFIX §5.2: фото к позиции. Стиль плиты — как у dueDate выше.
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            onTap: draft.uploadingPhoto ? null : onPickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x12,
                vertical: AppSpacing.x10,
              ),
              decoration: BoxDecoration(
                color: AppColors.n0,
                border: Border.all(color: AppColors.n200, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  Icon(
                    draft.photo != null
                        ? Icons.check_circle_outline
                        : Icons.add_photo_alternate_outlined,
                    size: 18,
                    color: draft.photo != null
                        ? AppColors.greenDark
                        : AppColors.n500,
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      draft.uploadingPhoto
                          ? 'Загрузка фото…'
                          : draft.photo == null
                              ? 'Фото (опционально)'
                              : 'Фото прикреплено',
                      style: AppTextStyles.body.copyWith(
                        color: draft.photo == null
                            ? AppColors.n400
                            : AppColors.n900,
                      ),
                    ),
                  ),
                  if (draft.uploadingPhoto)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (draft.photo != null)
                    InkWell(
                      onTap: onRemovePhoto,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.n400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inlineDec(String label) => InputDecoration(
  labelText: label,
  labelStyle: AppTextStyles.caption,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
  ),
);

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
  filled: true,
  fillColor: AppColors.n0,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
  ),
);
