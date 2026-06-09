-- NEWFIX §7.1 — stage-level PDF report.
-- Новый ExportKind value для async-генерации отчёта по одному этапу
-- (по образцу project_report_pdf, но ограничено stageId).

ALTER TYPE "ExportKind" ADD VALUE 'stage_report_pdf';
