import 'dart:io';

import 'package:dio/dio.dart';

import '../config/env.dart';

/// Unsigned direct-to-Cloudinary upload, matching the website's own
/// `uploadToCloudinary` helpers (same cloud name + upload preset —
/// `sharfians_gallery` is reused across gallery, event payment proofs, and
/// career CVs on the website, differentiated only by the `folder` param).
class CloudinaryUploader {
  static final _dio = Dio();

  static Future<String> upload(
    File file, {
    String uploadPreset = 'sharfians_gallery',
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    final url =
        'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/auto/upload';
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'upload_preset': uploadPreset,
      'folder': ?folder,
    });
    final res = await _dio.post(
      url,
      data: form,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    return res.data['secure_url'] as String;
  }
}
