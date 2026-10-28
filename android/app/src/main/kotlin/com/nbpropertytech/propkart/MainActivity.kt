package com.nbpropertytech.propkart

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nbpropertytech.propkart/media_saver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveZipToDownloads" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "property_images.zip"
                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Bytes cannot be null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val path = saveZip(bytes, fileName)
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }
                "saveImagesToGallery" -> {
                    val images = call.argument<List<Map<String, Any>>>("images")
                    val albumName = call.argument<String>("albumName") ?: "PropKart"
                    if (images == null) {
                        result.error("INVALID_ARGS", "Images list cannot be null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        var savedCount = 0
                        for (img in images) {
                            val bytes = img["bytes"] as? ByteArray ?: continue
                            val fileName = img["fileName"] as? String ?: "image_${savedCount + 1}.jpg"
                            if (saveImage(bytes, fileName, albumName)) {
                                savedCount++
                            }
                        }
                        result.success(savedCount)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveZip(bytes: ByteArray, fileName: String): String {
        val resolver = applicationContext.contentResolver
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/zip")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw Exception("Failed to create download URI")
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            }
            contentValues.clear()
            contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)
            return "Downloads/$fileName"
        } else {
            @Suppress("DEPRECATION")
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val file = File(downloadsDir, fileName)
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(applicationContext, arrayOf(file.absolutePath), arrayOf("application/zip"), null)
            return file.absolutePath
        }
    }

    private fun saveImage(bytes: ByteArray, fileName: String, albumName: String): Boolean {
        val resolver = applicationContext.contentResolver
        val mimeType = when {
            fileName.endsWith(".png", true) -> "image/png"
            fileName.endsWith(".webp", true) -> "image/webp"
            else -> "image/jpeg"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val subDir = if (albumName.isNotEmpty()) "${Environment.DIRECTORY_PICTURES}/$albumName" else Environment.DIRECTORY_PICTURES
            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                put(MediaStore.Images.Media.RELATIVE_PATH, subDir)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues) ?: return false
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            }
            contentValues.clear()
            contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)
            return true
        } else {
            @Suppress("DEPRECATION")
            val picturesDir = if (albumName.isNotEmpty()) {
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), albumName)
            } else {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            }
            if (!picturesDir.exists()) picturesDir.mkdirs()
            val file = File(picturesDir, fileName)
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(applicationContext, arrayOf(file.absolutePath), arrayOf(mimeType), null)
            return true
        }
    }
}
