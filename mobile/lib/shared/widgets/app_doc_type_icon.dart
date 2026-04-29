import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Цветная иконка-квадрат для типа документа в `f-docs`.
///
/// 44×44 r12, фон зависит от mime-type:
/// - PDF → redBg + redDot
/// - DWG/DXF → brandLight + brand
/// - JPG/PNG/HEIC → yellowBg + #D97706
/// - XLSX/XLS/CSV → greenLight + greenDark
/// - DOCX/DOC/TXT → brandLight + brand
/// - else → n100 + n500
class AppDocTypeIcon extends StatelessWidget {
  const AppDocTypeIcon({
    required this.mimeType,
    this.size = 44,
    super.key,
  });

  final String mimeType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = _palette(mimeType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      alignment: Alignment.center,
      child: Icon(p.icon, size: size * 0.45, color: p.fg),
    );
  }
}

class _DocPalette {
  const _DocPalette(this.bg, this.fg, this.icon);
  final Color bg;
  final Color fg;
  final IconData icon;
}

_DocPalette _palette(String mime) {
  final m = mime.toLowerCase();
  if (m.contains('pdf')) {
    return const _DocPalette(
      AppColors.redBg,
      AppColors.redDot,
      Icons.picture_as_pdf_outlined,
    );
  }
  if (m.contains('dwg') || m.contains('dxf') || m.contains('autocad')) {
    return const _DocPalette(
      AppColors.brandLight,
      AppColors.brand,
      Icons.architecture_outlined,
    );
  }
  if (m.startsWith('image/') ||
      m.contains('jpg') ||
      m.contains('jpeg') ||
      m.contains('png') ||
      m.contains('heic') ||
      m.contains('webp')) {
    return const _DocPalette(
      AppColors.yellowBg,
      Color(0xFFD97706),
      Icons.image_outlined,
    );
  }
  if (m.contains('sheet') ||
      m.contains('xlsx') ||
      m.contains('xls') ||
      m.contains('csv')) {
    return const _DocPalette(
      AppColors.greenLight,
      AppColors.greenDark,
      Icons.table_chart_outlined,
    );
  }
  if (m.contains('word') ||
      m.contains('docx') ||
      m.contains('doc') ||
      m.contains('text')) {
    return const _DocPalette(
      AppColors.brandLight,
      AppColors.brand,
      Icons.description_outlined,
    );
  }
  return const _DocPalette(
    AppColors.n100,
    AppColors.n500,
    Icons.insert_drive_file_outlined,
  );
}
