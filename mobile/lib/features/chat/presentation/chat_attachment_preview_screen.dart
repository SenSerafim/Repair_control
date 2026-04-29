import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Sentinel-результат от [ChatAttachmentPreviewScreen]: `confirmed=true` если
/// пользователь нажал send, `caption` — опциональная подпись.
class ChatAttachmentResult {
  const ChatAttachmentResult({required this.caption});
  final String? caption;
}

/// `f-chat-upload` из дизайна — превью изображения перед отправкой.
///
/// Возвращает [ChatAttachmentResult] при подтверждении, либо null при cancel.
class ChatAttachmentPreviewScreen extends StatefulWidget {
  const ChatAttachmentPreviewScreen({required this.file, super.key});

  final File file;

  @override
  State<ChatAttachmentPreviewScreen> createState() =>
      _ChatAttachmentPreviewScreenState();
}

class _ChatAttachmentPreviewScreenState
    extends State<ChatAttachmentPreviewScreen> {
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n900,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: Container(
                color: AppColors.n900,
                alignment: Alignment.center,
                child: InteractiveViewer(
                  child: Image.file(
                    widget.file,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            _Bottom(
              captionCtrl: _captionCtrl,
              onSend: () {
                Navigator.of(context).pop(
                  ChatAttachmentResult(
                    caption: _captionCtrl.text.trim().isEmpty
                        ? null
                        : _captionCtrl.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.n0),
            onPressed: onClose,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Превью',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.n0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.captionCtrl, required this.onSend});

  final TextEditingController captionCtrl;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: AppColors.n900,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              decoration: BoxDecoration(
                color: AppColors.n800,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: TextField(
                controller: captionCtrl,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.n0,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  hintText: 'Подпись (необязательно)…',
                  hintStyle: TextStyle(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.brandButton,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.shBlue,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.n0,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
