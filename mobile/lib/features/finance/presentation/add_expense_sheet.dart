import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/image_compress.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

/// ТЗ NEWFIX §5.1: bottom-sheet «Добавить расход» (CoinKeeper-flow).
/// Поля сверху вниз: Фото чека (опц.) · Этап (опц.) · Категория · Название ·
/// Сумма · Комментарий.
/// Возвращает созданный [Expense] (или null, если отменили) — чтобы вызывающий
/// мог открыть деталь-шит сразу после добавления (Егор 23.06.2026).
Future<Expense?> showAddExpenseSheet(
  BuildContext context, {
  required String projectId,
  String? initialStageId,
}) async {
  // Используем общий враппер showAppBottomSheet: root-navigator (перекрывает
  // нижний таб-бар), maxHeight 0.92 (sheet больше не наезжает на status bar),
  // handle, SafeArea и компенсация клавиатуры. Своя реализация тянулась до
  // самой верхней кромки и обрезала заголовок (Егор 23.06.2026).
  return showAppBottomSheet<Expense>(
    context: context,
    child: _AddExpenseSheet(
      projectId: projectId,
      initialStageId: initialStageId,
    ),
  );
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet({required this.projectId, this.initialStageId});

  final String projectId;
  final String? initialStageId;

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.materials;
  String? _stageId;
  bool _busy = false;
  String? _error;

  /// NEWFIX TZ-фронт §5.1 — фото чека: опционально, до отправки сохраняем
  /// fileKey + локальные байты для превью.
  String? _receiptFileKey;
  Uint8List? _receiptThumb;
  bool _uploadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _stageId = widget.initialStageId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    if (_uploadingReceipt || _busy) return;
    setState(() {
      _uploadingReceipt = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) {
        if (mounted) setState(() => _uploadingReceipt = false);
        return;
      }
      final raw = await picked.readAsBytes();
      final compressed = compressImage(raw);
      if (compressed == null) {
        if (!mounted) return;
        setState(() {
          _uploadingReceipt = false;
          _error = 'Не удалось обработать фото';
        });
        return;
      }
      final repo = ref.read(expensesRepositoryProvider);
      final presigned = await repo.presignReceipt(
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
        _receiptFileKey = presigned.fileKey;
        _receiptThumb = compressed.bytes;
        _uploadingReceipt = false;
      });
    } on ExpensesException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingReceipt = false;
        _error = e.failure.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadingReceipt = false;
        _error = 'Не удалось загрузить фото';
      });
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final kopecks = MoneyInput.readKopecks(_amount);
    if (name.isEmpty) {
      setState(() => _error = 'Введите название расхода');
      return;
    }
    if (kopecks == null || kopecks <= 0) {
      setState(() => _error = 'Введите сумму');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(expensesRepositoryProvider)
          .create(
            projectId: widget.projectId,
            category: _category,
            name: name,
            amountKopecks: kopecks,
            stageId: _stageId,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            photoKey: _receiptFileKey,
          );
      ref.invalidate(projectExpensesProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ExpensesException catch (e) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить: ${e.failure.name}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle, SafeArea, maxHeight и компенсацию клавиатуры даёт враппер
    // showAppBottomSheet — здесь только скролл-контент.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка: заголовок + явная кнопка закрытия (Егор 23.06.2026 —
          // «кнопки назад нет»). По swipe-down sheet тоже закрывается.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Добавить расход',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                // Шит типизирован Expense? — закрытие должно вернуть null,
                // а не false. Иначе вызывающий получает bool в переменной
                // типа Expense? и падает с TypeError при попытке открыть
                // деталь-шит → чёрный экран (Егор 29.06.2026).
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop<Expense>(),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x14),
          if (_error != null) ...[
            AppInlineError(message: _error!),
            const SizedBox(height: AppSpacing.x10),
          ],
          _ReceiptPicker(
            thumb: _receiptThumb,
            uploading: _uploadingReceipt,
            onPick: _pickReceipt,
            onClear: () => setState(() {
              _receiptFileKey = null;
              _receiptThumb = null;
            }),
          ),
          const SizedBox(height: AppSpacing.x14),
          const Text('Этап (опционально)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          _StagePicker(
            projectId: widget.projectId,
            selectedStageId: _stageId,
            onChanged: (id) => setState(() => _stageId = id),
          ),
          const SizedBox(height: AppSpacing.x14),
          const Text('Категория', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in ExpenseCategory.values)
                ChoiceChip(
                  label: Text(c.displayName),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x14),
          const Text('Название', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: 'Например, «Цемент М500»',
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          const Text('Сумма', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          MoneyInput(controller: _amount, label: 'Сумма'),
          const SizedBox(height: AppSpacing.x14),
          const Text('Комментарий (опционально)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Детали'),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(label: 'Добавить', isLoading: _busy, onPressed: _submit),
        ],
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
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: const Text('Без этапа'),
            selected: selectedStageId == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final s in stages)
            ChoiceChip(
              label: Text(_stageLabel(s)),
              selected: selectedStageId == s.id,
              onSelected: (_) => onChanged(s.id),
            ),
        ],
      ),
    );
  }

  String _stageLabel(Stage stage) {
    final title = stage.title.trim();
    if (title.isNotEmpty) return title;
    return 'Этап ${stage.orderIndex + 1}';
  }
}

/// NEWFIX TZ-фронт §5.1 — большая кнопка-плейсхолдер «📷 Сфотографировать
/// чек» вверху модалки расхода. Опционально, можно пропустить.
class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
    required this.thumb,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? thumb;
  final bool uploading;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (thumb != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.x8),
        decoration: BoxDecoration(
          color: AppColors.n50,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: Image.memory(
                thumb!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            const Expanded(
              child: Text(
                'Чек прикреплён',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n800,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClear,
              tooltip: 'Удалить фото',
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Сфотографировать чек'),
            onPressed: uploading ? null : () => onPick(ImageSource.camera),
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        IconButton.outlined(
          icon: uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
          onPressed: uploading ? null : () => onPick(ImageSource.gallery),
          tooltip: 'Из галереи',
        ),
      ],
    );
  }
}
