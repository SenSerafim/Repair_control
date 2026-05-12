-- Добавляем значение project_summary_txt в enum ExportKind (S5 fix — TXT-сводка проекта).
ALTER TYPE "ExportKind" ADD VALUE IF NOT EXISTS 'project_summary_txt';
