import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'export_job.freezed.dart';

enum ExportKind {
  feedPdf,
  projectReportPdf,
  projectZip,
  stageReportPdf;

  static ExportKind fromString(String? raw) => switch (raw) {
    'project_zip' => ExportKind.projectZip,
    'project_report_pdf' => ExportKind.projectReportPdf,
    'stage_report_pdf' => ExportKind.stageReportPdf,
    // Историческое значение TXT — больше не предлагаем, но если бэкенд вернёт
    // запись со старым kind, считаем её отчётом PDF (бекенд тоже отдаёт PDF
    // для legacy-jobs, см. ExportProcessor).
    'project_summary_txt' => ExportKind.projectReportPdf,
    _ => ExportKind.feedPdf,
  };

  String get apiValue => switch (this) {
    ExportKind.feedPdf => 'feed_pdf',
    ExportKind.projectReportPdf => 'project_report_pdf',
    ExportKind.projectZip => 'project_zip',
    ExportKind.stageReportPdf => 'stage_report_pdf',
  };

  String get displayName => switch (this) {
    ExportKind.feedPdf => 'PDF ленты',
    ExportKind.projectReportPdf => 'Полный отчёт (PDF)',
    ExportKind.projectZip => 'ZIP проекта',
    ExportKind.stageReportPdf => 'Отчёт по этапу (PDF)',
  };

  String get subtitle => switch (this) {
    ExportKind.feedPdf =>
      'Хронология событий проекта за выбранный период.',
    ExportKind.projectReportPdf =>
      'Юридически оформленный отчёт: команда, бюджет, движения средств, этапы и шаги с фото, материалы, инструменты, документы и лента событий.',
    ExportKind.projectZip =>
      'Архив со всеми документами проекта и фотофиксацией шагов плюс PDF-отчёт.',
    ExportKind.stageReportPdf =>
      'Отчёт по одному этапу: фото шагов, материалы, документы, бюджет этапа.',
  };
}

enum ExportStatus {
  queued,
  running,
  done,
  failed,
  expired;

  static ExportStatus fromString(String? raw) {
    switch (raw) {
      case 'running':
        return ExportStatus.running;
      case 'done':
        return ExportStatus.done;
      case 'failed':
        return ExportStatus.failed;
      case 'expired':
        return ExportStatus.expired;
      case 'queued':
      default:
        return ExportStatus.queued;
    }
  }

  String get apiValue => switch (this) {
    ExportStatus.queued => 'queued',
    ExportStatus.running => 'running',
    ExportStatus.done => 'done',
    ExportStatus.failed => 'failed',
    ExportStatus.expired => 'expired',
  };

  String get displayName => switch (this) {
    ExportStatus.queued => 'В очереди',
    ExportStatus.running => 'Готовим',
    ExportStatus.done => 'Готов',
    ExportStatus.failed => 'Ошибка',
    ExportStatus.expired => 'Истёк',
  };

  Semaphore get semaphore => switch (this) {
    ExportStatus.queued => Semaphore.plan,
    ExportStatus.running => Semaphore.blue,
    ExportStatus.done => Semaphore.green,
    ExportStatus.failed => Semaphore.red,
    ExportStatus.expired => Semaphore.plan,
  };
}

@freezed
class ExportJob with _$ExportJob {
  const factory ExportJob({
    required String id,
    required String projectId,
    required ExportKind kind,
    required ExportStatus status,
    String? fileKey,
    String? downloadUrl,
    int? sizeBytes,
    String? failureReason,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) = _ExportJob;

  static ExportJob parse(Map<String, dynamic> json) => ExportJob(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    kind: ExportKind.fromString(json['kind'] as String?),
    status: ExportStatus.fromString(json['status'] as String?),
    fileKey: json['fileKey'] as String?,
    downloadUrl: json['downloadUrl'] as String? ?? json['url'] as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    failureReason: json['failureReason'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    startedAt: _d(json['startedAt']),
    completedAt: _d(json['completedAt']),
    expiresAt: _d(json['expiresAt']),
  );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
