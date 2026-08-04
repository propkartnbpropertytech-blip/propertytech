import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:crypto/crypto.dart';
import '../api/api_constants.dart';
import 'dio_client.dart';

class CloudinaryUploader {
  /// Uploads a file directly to Cloudinary using a signed signature from Supabase Edge Functions.
  /// If the signature request fails or Cloudinary fails, it falls back to direct upload to Supabase Storage.
  static Future<String> upload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
    required String resourceType, // 'image' or 'video'
    String folder = 'properties',
    String fallbackEndpoint = '/properties/upload-media',
  }) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        // Calculate signature directly on the client side to avoid Edge Function fetch block/CORS issues
        final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        const String transformation = 'q_70';
        
        // Alphabetical order: folder, timestamp, transformation
        final String toSign = 'folder=$folder&timestamp=$timestamp&transformation=$transformation${ApiConstants.cloudinaryApiSecret}';
        final List<int> bytesToSign = utf8.encode(toSign);
        final String signature = sha1.convert(bytesToSign).toString();

        final String apiKey = ApiConstants.cloudinaryApiKey;
        final String cloudName = ApiConstants.cloudinaryCloudName;
        final String targetFolder = folder;

        // 2. Upload directly to Cloudinary
        final cloudinaryUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );

          final formData = FormData.fromMap({
            'file': multipartFile,
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
            'folder': targetFolder,
            'transformation': transformation,
          });

          final cleanDio = Dio();
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
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );

          final formData = FormData.fromMap({
            'file': multipartFile,
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
            'folder': targetFolder,
            'transformation': transformation,
          });

          final cleanDio = Dio();
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
        
        final multipartFile = MultipartFile.fromBytes(
          bytes,
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
