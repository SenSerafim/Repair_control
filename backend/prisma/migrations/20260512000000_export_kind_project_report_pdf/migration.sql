-- Добавляем значение project_report_pdf в enum ExportKind — полный отчёт
-- проекта в PDF (заменяет TXT-сводку). TXT-вариант (project_summary_txt)
-- остаётся в enum для совместимости со старыми записями ExportJob, но
-- кодом более не предлагается и не обрабатывается.
ALTER TYPE "ExportKind" ADD VALUE IF NOT EXISTS 'project_report_pdf';
