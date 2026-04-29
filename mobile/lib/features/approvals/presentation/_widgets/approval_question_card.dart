import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../steps/domain/question.dart';

/// Purple card с открытым вопросом — `d-question-reply` (карточка вопроса
/// в шаге). По дизайну — purple (а не yellow), это «вопрос», а не warning.
///
/// Заголовок «Вопрос: …», автор + дата, поле «Написать ответ…» (read-only,
/// открывает ask-question-sheet или sheet ответа на тап).
class ApprovalQuestionCard extends StatelessWidget {
  const ApprovalQuestionCard({
    required this.question,
    required this.onTap,
    super.key,
  });

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.purple, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Text(
                  'Вопрос: ${question.text}',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Открыт ${df.format(question.createdAt)}',
            style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x10),
          Material(
            color: AppColors.n50,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.n200),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Написать ответ...',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.n400,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
