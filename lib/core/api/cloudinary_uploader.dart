import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import '../api/api_constants.dart';
import 'dio_client.dart';

class CloudinaryUploader {
  /// Uploads a file directly to Cloudinary using a signed signature from Supabase Edge Functions.
  /// If the signature request fails or Cloudinary fails, it falls back to direct upload to Supabase Storage.
  ///
  /// For PDFs, prefer [resourceType] `image` (not `raw`) so Cloudinary allows public CDN delivery.
  /// Many Cloudinary accounts block public `raw` PDF/ZIP URLs with ACL/401 errors.
  static Future<String> upload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
    required String resourceType, // 'image', 'video', or 'raw'
    String folder = 'properties',
    String fallbackEndpoint = '/properties/upload-media',
    bool skipTransformation = false,
  }) async {
    final bool isPdf = mimeType.toLowerCase().contains('pdf') ||
        filename.toLowerCase().endsWith('.pdf');
    // PDFs must not use image quality transforms — they break the file.
    final bool applyTransformation =
        resourceType == 'image' && !skipTransformation && !isPdf;

    if (ApiConstants.useSupabaseDirect) {
      try {
        // Calculate signature directly on the client side to avoid Edge Function fetch block/CORS issues
        final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Alphabetical order of params included in the request (excluding file/api_key/resource_type)
        final String toSign = applyTransformation
            ? 'folder=$folder&timestamp=$timestamp&transformation=q_70${ApiConstants.cloudinaryApiSecret}'
            : 'folder=$folder&timestamp=$timestamp${ApiConstants.cloudinaryApiSecret}';
        final List<int> bytesToSign = utf8.encode(toSign);
        final String signature = sha1.convert(bytesToSign).toString();

        final String apiKey = ApiConstants.cloudinaryApiKey;
        final String cloudName = ApiConstants.cloudinaryCloudName;
        final String targetFolder = folder;

        // Ensure binary payload is a concrete Uint8List (web FormData can corrupt List<int>)
        final uploadBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

        // 2. Upload directly to Cloudinary
        final cloudinaryUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

        final multipartFile = MultipartFile.fromBytes(
          uploadBytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        );

        final formData = FormData.fromMap({
          'file': multipartFile,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'folder': targetFolder,
          if (applyTransformation) 'transformation': 'q_70',
        });

        final cleanDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(minutes: 10),
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(minutes: 10),
          ),
        );
        final cloudResponse = await cleanDio.post(
          cloudinaryUrl,
          data: formData,
        );

        if (cloudResponse.statusCode == 200 || cloudResponse.statusCode == 201) {
          final secureUrl = cloudResponse.data['secure_url'] as String?;
          if (secureUrl != null && secureUrl.isNotEmpty) {
            return secureUrl;
          }
        }
        throw Exception('Cloudinary upload returned status ${cloudResponse.statusCode}');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cloudinary Direct Upload failed: $e');
        }
        rethrow;
      }
    } else {
      // Original Node.js REST API Upload logic (Backward compatible)
      try {
        final sigResponse = await DioClient.dio.post(
          '/properties/cloudinary-signature',
          data: {
            'resource_type': resourceType,
            'folder': folder,
          },
        );

        if (sigResponse.data != null && sigResponse.data['success'] == true) {
          final data = sigResponse.data['data'] as Map<String, dynamic>;
          final String signature = data['signature'];
          final int timestamp = data['timestamp'];
          final String apiKey = data['apiKey'];
          final String cloudName = data['cloudName'];
          final String targetFolder = data['folder'];
          final String transformation = data['transformation'] ?? 'q_70';

          final cloudinaryUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
          final uploadBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

          final multipartFile = MultipartFile.fromBytes(
            uploadBytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );

          final formData = FormData.fromMap({
            'file': multipartFile,
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
            'folder': targetFolder,
            if (applyTransformation) 'transformation': transformation,
          });

          final cleanDio = Dio(
            BaseOptions(
              connectTimeout: const Duration(minutes: 10),
              receiveTimeout: const Duration(minutes: 10),
              sendTimeout: const Duration(minutes: 10),
            ),
          );
          final cloudResponse = await cleanDio.post(
            cloudinaryUrl,
            data: formData,
          );

          if (cloudResponse.statusCode == 200 || cloudResponse.statusCode == 201) {
            final secureUrl = cloudResponse.data['secure_url'] as String?;
            if (secureUrl != null && secureUrl.isNotEmpty) {
              return secureUrl;
            }
          }
          throw Exception('Cloudinary upload returned status ${cloudResponse.statusCode}');
        }
        throw Exception('Backend signature generation failed.');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cloudinary Signed Upload failed, falling back to direct backend upload: $e');
        }

        final uploadBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
        final multipartFile = MultipartFile.fromBytes(
          uploadBytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        );

        final formData = FormData.fromMap({
          'file': multipartFile,
        });

        final response = await DioClient.dio.post(
          fallbackEndpoint,
          data: formData,
        );

        if (response.data != null && response.data['success'] == true) {
          return response.data['data']['url'] as String;
        }
        throw Exception(response.data?['message'] ?? 'Upload failed.');
      }
    }
  }

  /// Uploads a service-agent document into Cloudinary folder `library_docs` only.
  /// Never uploads to Supabase Storage — returns a Cloudinary `res.cloudinary.com` URL.
  static Future<String> uploadServiceAgentPdf({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Empty file — cannot upload to Cloudinary.');
    }

    final uploadBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final lower = safeName.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    final String mimeType;
    final String uploadName;
    if (isPdf) {
      mimeType = 'application/pdf';
      uploadName = safeName;
    } else if (isImage) {
      mimeType = lower.endsWith('.png')
          ? 'image/png'
          : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      uploadName = safeName;
    } else {
      // Default documents to PDF naming for library_docs
      mimeType = 'application/pdf';
      uploadName = safeName.endsWith('.pdf') ? safeName : '$safeName.pdf';
    }

    final cloudinaryUrl = await upload(
      bytes: uploadBytes,
      filename: uploadName,
      mimeType: mimeType,
      resourceType: 'image',
      folder: 'library_docs',
      skipTransformation: true,
    );

    if (cloudinaryUrl.isEmpty ||
        !cloudinaryUrl.startsWith('http') ||
        !cloudinaryUrl.contains('res.cloudinary.com') ||
        !cloudinaryUrl.contains(ApiConstants.cloudinaryCloudName)) {
      throw Exception(
        'Cloudinary upload failed — expected ${ApiConstants.cloudinaryCloudName}/library_docs URL, got: $cloudinaryUrl',
      );
    }

    // Hard-reject any accidental Supabase Storage URL
    if (cloudinaryUrl.contains('supabase.co') || cloudinaryUrl.contains('storage/v1')) {
      throw Exception('Refusing to save Supabase Storage URL. File must be on Cloudinary.');
    }

    if (kDebugMode) {
      print('✅ Cloudinary library_docs only: $cloudinaryUrl (${uploadBytes.length} bytes)');
    }

    return cloudinaryUrl;
  }

  /// Converts a Cloudinary PDF URL into a publicly deliverable image preview URL.
  /// Free Cloudinary plans often block direct PDF delivery with 401 ACL errors.
  static String toPublicPreviewUrl(String cloudinaryUrl) {
    if (!cloudinaryUrl.contains('res.cloudinary.com')) return cloudinaryUrl;
    if (cloudinaryUrl.contains('/upload/f_')) return cloudinaryUrl;
    return cloudinaryUrl.replaceFirst('/upload/', '/upload/f_jpg/');
  }

  /// Extracts the folder and public ID from a Cloudinary URL
  static String? extractPublicId(String url) {
    try {
      final decodedUrl = Uri.decodeFull(url);
      final uri = Uri.parse(decodedUrl);
      final pathSegments = uri.pathSegments;

      final uploadIdx = pathSegments.indexOf('upload');
      if (uploadIdx == -1) return null;

      final afterUpload = pathSegments.sublist(uploadIdx + 1);
      if (afterUpload.isEmpty) return null;

      int startIdx = 0;
      while (startIdx < afterUpload.length) {
        final segment = afterUpload[startIdx];
        final isVersion = RegExp(r'^v\d+$').hasMatch(segment);
        final isTransformation = segment.contains('_') || segment.contains(',');

        if (isVersion || isTransformation) {
          startIdx++;
        } else {
          break;
        }
      }

      if (startIdx >= afterUpload.length) return null;

      final remainingSegments = afterUpload.sublist(startIdx);
      final fullPath = remainingSegments.join('/');

      final dotIdx = fullPath.lastIndexOf('.');
      if (dotIdx != -1) {
        return fullPath.substring(0, dotIdx);
      }
      return fullPath;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a Cloudinary asset permanently
  static Future<void> delete({
    required String url,
    required String resourceType, // 'image' or 'video'
  }) async {
    try {
      final publicId = extractPublicId(url);
      if (publicId == null) {
        if (kDebugMode) {
          print('⚠️ Could not extract public_id from Cloudinary URL: $url');
        }
        return;
      }

      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String toSign = 'public_id=$publicId&timestamp=$timestamp${ApiConstants.cloudinaryApiSecret}';
      final List<int> bytesToSign = utf8.encode(toSign);
      final String signature = sha1.convert(bytesToSign).toString();

      final String apiKey = ApiConstants.cloudinaryApiKey;
      final String cloudName = ApiConstants.cloudinaryCloudName;

      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy';

      final formData = FormData.fromMap({
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      final cleanDio = Dio();
      final response = await cleanDio.post(deleteUrl, data: formData);
      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result == 'ok') {
          if (kDebugMode) {
            print('✅ Cloudinary asset deleted: $publicId');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Cloudinary delete result for $publicId: $result');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Cloudinary delete failed for $publicId: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Cloudinary delete failed: $e');
      }
    }
  }
}
