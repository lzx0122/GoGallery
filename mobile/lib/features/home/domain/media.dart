import 'dart:io';
import '../../../core/config/app_config.dart';

class Media {
  final String id;
  final String userId;
  final String originalFilename;
  final String fileHash;
  final int sizeBytes;
  final int width;
  final int height;
  final double duration;
  final String mimeType;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  final String cameraMake;
  final String cameraModel;
  final String exposureTime;
  final double aperture;
  final int iso;
  final String blurHash;
  final String dominantColor;
  final DateTime uploadedAt;

  // Uploading state
  final bool isUploading;
  final bool isDuplicate;
  final bool isHighlighted;
  final double uploadProgress;
  final File? localFile;

  Media({
    required this.id,
    required this.userId,
    required this.originalFilename,
    required this.fileHash,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.duration,
    required this.mimeType,
    this.takenAt,
    this.latitude,
    this.longitude,
    required this.cameraMake,
    required this.cameraModel,
    required this.exposureTime,
    required this.aperture,
    required this.iso,
    required this.blurHash,
    required this.dominantColor,
    required this.uploadedAt,
    this.isUploading = false,
    this.isDuplicate = false,
    this.isHighlighted = false,
    this.uploadProgress = 0.0,
    this.localFile,
  });

  Media copyWith({
    String? id,
    String? userId,
    String? originalFilename,
    String? fileHash,
    int? sizeBytes,
    int? width,
    int? height,
    double? duration,
    String? mimeType,
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    String? cameraMake,
    String? cameraModel,
    String? exposureTime,
    double? aperture,
    int? iso,
    String? blurHash,
    String? dominantColor,
    DateTime? uploadedAt,
    bool? isUploading,
    bool? isDuplicate,
    bool? isHighlighted,
    double? uploadProgress,
    File? localFile,
  }) {
    return Media(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalFilename: originalFilename ?? this.originalFilename,
      fileHash: fileHash ?? this.fileHash,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      mimeType: mimeType ?? this.mimeType,
      takenAt: takenAt ?? this.takenAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      exposureTime: exposureTime ?? this.exposureTime,
      aperture: aperture ?? this.aperture,
      iso: iso ?? this.iso,
      blurHash: blurHash ?? this.blurHash,
      dominantColor: dominantColor ?? this.dominantColor,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isUploading: isUploading ?? this.isUploading,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      localFile: localFile ?? this.localFile,
    );
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      originalFilename: json['original_filename'] as String? ?? '',
      fileHash: json['file_hash'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      mimeType: json['mime_type'] as String? ?? '',
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'])
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cameraMake: json['camera_make'] as String? ?? '',
      cameraModel: json['camera_model'] as String? ?? '',
      exposureTime: json['exposure_time'] as String? ?? '',
      aperture: (json['aperture'] as num?)?.toDouble() ?? 0.0,
      iso: json['iso'] as int? ?? 0,
      blurHash: json['blur_hash'] as String? ?? '',
      dominantColor: json['dominant_color'] as String? ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  // Helper to get full URL (assuming local dev for now)
  // In production, this should be configured via environment variables
  String get url {
    final baseUrl = AppConfig.baseUrl;

    // Construct path: /uploads/uid/year/month/hash.ext
    // But wait, the backend stores relative path in DB but doesn't expose it directly in JSON?
    // Ah, the backend model has `StoragePath` but it is `json:"-"`.
    // We need to construct it or the backend should serve it.
    // Currently the backend doesn't have a "Serve File" API, only Upload and List.
    // We need to add a Static File Server in Go or Nginx.
    // For now, let's assume the Go server serves `uploads/` directory statically.

    // Wait, I missed adding Static file serving in Go!
    // I should fix the backend to serve static files first.
    return '$baseUrl/uploads/$userId/${uploadedAt.year}/${uploadedAt.month.toString().padLeft(2, '0')}/$fileHash${_getExtension()}';
  }

  String _getExtension() {
    // Simple extension guesser
    if (mimeType == 'image/jpeg') return '.jpg';
    if (mimeType == 'image/png') return '.png';
    if (mimeType == 'video/mp4') return '.mp4';
    return '';
  }
}
