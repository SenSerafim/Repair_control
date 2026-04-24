import 'package:freezed_annotation/freezed_annotation.dart';

part 'step_photo.freezed.dart';

@freezed
class StepPhoto with _$StepPhoto {
  const factory StepPhoto({
    required String id,
    required String stepId,
    required String fileKey,
    String? thumbKey,
    required String mimeType,
    required int sizeBytes,
    required String uploadedBy,
    required bool exifCleared,
    required DateTime createdAt,
    String? url,
    String? thumbUrl,
  }) = _StepPhoto;

  static StepPhoto parse(Map<String, dynamic> json) => StepPhoto(
        id: json['id'] as String,
        stepId: json['stepId'] as String,
        fileKey: json['fileKey'] as String,
        thumbKey: json['thumbKey'] as String?,
        mimeType: json['mimeType'] as String,
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        uploadedBy: json['uploadedBy'] as String? ?? '',
        exifCleared: json['exifCleared'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        url: json['url'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
      );
}
