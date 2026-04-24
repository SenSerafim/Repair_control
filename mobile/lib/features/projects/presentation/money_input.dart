import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';

/// Поле ввода денежной суммы.
/// Вводится в рублях (целое число), сохраняется в копейках (×100).
class MoneyInput extends StatelessWidget {
  const MoneyInput({
    required this.controller,
    this.label,
    this.hint,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
        ],
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
          ],
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Text(
                '₽',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: AppColors.n200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: AppColors.n200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: AppColors.brand,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Берёт ввод и возвращает копейки (или null если пусто).
  static int? readKopecks(TextEditingController c) =>
      Money.parseInputToKopecks(c.text);

  /// Устанавливает значение из копеек.
  static void setFromKopecks(TextEditingController c, int kopecks) {
    c.text = Money.format(
      kopecks,
      currency: '',
    ).trim();
  }
}
