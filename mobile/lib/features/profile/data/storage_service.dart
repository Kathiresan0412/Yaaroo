import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Exception thrown when photo upload validation fails.
class PhotoValidationException implements Exception {
  final String message;
  const PhotoValidationException(this.message);

  @override
  String toString() => 'PhotoValidationException: $message';
}

/// Exception thrown when photo upload fails.
class PhotoUploadException implements Exception {
  final String message;
  final File? retainedImage;
  const PhotoUploadException(this.message, {this.retainedImage});

  @override
  String toString() => 'PhotoUploadException: $message';
}

/// Supported image formats for upload.
const Set<String> supportedFormats = {'.jpg', '.jpeg', '.png', '.heic'};

/// Maximum file size before compression (10 MB).
const int maxFileSizeBeforeCompression = 10 * 1024 * 1024;

/// Maximum file size after compression (1 MB).
const int maxFileSizeAfterCompression = 1 * 1024 * 1024;

/// Maximum resolution for compressed images.
const int maxResolution = 1080;

/// Maximum number of photos allowed per user profile.
const int maxPhotosPerUser = 6;

/// Abstract interface for photo storage operations.
abstract class PhotoStorageService {
  /// Compresses image to max 1080x1080 and 1MB, uploads to
  /// users/{uid}/photos/{uuid}.jpg, returns download URL.
  Future<String> uploadPhoto(String uid, File imageFile);

  /// Provides upload progress stream (0.0 to 1.0).
  Stream<double> get uploadProgress;

  /// Deletes a photo by its storage path.
  Future<void> deletePhoto(String storagePath);

  /// Validates whether the user can upload more photos.
  /// Returns true if photo count is below the maximum limit.
  Future<bool> canUploadPhoto(String uid, int currentPhotoCount);
}

/// Checks if the current photo count allows for an additional upload.
/// Returns true if [currentPhotoCount] is below [maxPhotosPerUser].
bool canAddPhoto(int currentPhotoCount) {
  return currentPhotoCount < maxPhotosPerUser;
}

/// Validates the file format is one of JPEG, PNG, or HEIC.
/// Returns true if valid, false otherwise.
bool isValidFileFormat(String filePath) {
  final extension = p.extension(filePath).toLowerCase();
  return supportedFormats.contains(extension);
}

/// Validates the file size is within the 10 MB limit before compression.
/// Returns true if valid, false otherwise.
bool isValidFileSize(int fileSizeBytes) {
  return fileSizeBytes <= maxFileSizeBeforeCompression;
}

/// Firebase Storage implementation of [PhotoStorageService].
class FirebasePhotoStorageService implements PhotoStorageService {
  final FirebaseStorage _storage;
  final Uuid _uuid;
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  FirebasePhotoStorageService({
    required FirebaseStorage storage,
    Uuid? uuid,
  })  : _storage = storage,
        _uuid = uuid ?? const Uuid();

  @override
  Stream<double> get uploadProgress => _progressController.stream;

  @override
  Future<bool> canUploadPhoto(String uid, int currentPhotoCount) async {
    return canAddPhoto(currentPhotoCount);
  }

  @override
  Future<String> uploadPhoto(String uid, File imageFile) async {
    // Validate file format
    if (!isValidFileFormat(imageFile.path)) {
      throw const PhotoValidationException(
        'Unsupported file format. Please use JPEG, PNG, or HEIC.',
      );
    }

    // Validate file size before compression
    final fileSize = await imageFile.length();
    if (!isValidFileSize(fileSize)) {
      throw const PhotoValidationException(
        'File is too large. Maximum size before compression is 10 MB.',
      );
    }

    try {
      // Compress the image
      final compressedFile = await _compressImage(imageFile);

      // Generate unique filename
      final fileName = '${_uuid.v4()}.jpg';
      final storagePath = 'users/$uid/photos/$fileName';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          _progressController.add(progress.clamp(0.0, 1.0));
        },
        onError: (_) {
          // Progress errors are non-fatal
        },
      );

      // Wait for upload completion
      await uploadTask;

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();

      // Emit final progress
      _progressController.add(1.0);

      // Clean up temporary compressed file if different from original
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
        } catch (_) {
          // Non-fatal: temp file cleanup failure
        }
      }

      return downloadUrl;
    } catch (e) {
      if (e is PhotoValidationException) rethrow;
      throw PhotoUploadException(
        'Upload failed: ${e.toString()}',
        retainedImage: imageFile,
      );
    }
  }

  @override
  Future<void> deletePhoto(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    await ref.delete();
  }

  /// Compresses the image to max 1080x1080 and max 1MB.
  Future<File> _compressImage(File imageFile) async {
    final filePath = imageFile.path;
    final targetPath =
        '${p.withoutExtension(filePath)}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Start with quality 85 and reduce if needed
    int quality = 85;
    File? result;

    while (quality >= 20) {
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        minWidth: maxResolution,
        minHeight: maxResolution,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw const PhotoUploadException(
          'Image compression failed. Please try a different image.',
        );
      }

      result = File(compressedXFile.path);
      final compressedSize = await result.length();

      if (compressedSize <= maxFileSizeAfterCompression) {
        return result;
      }

      // Reduce quality and try again
      quality -= 15;
    }

    // If we still can't get under 1MB at lowest quality, return last attempt
    if (result != null) {
      return result;
    }

    throw const PhotoUploadException(
      'Unable to compress image to required size. Please choose a smaller image.',
    );
  }

  /// Disposes of the progress stream controller.
  void dispose() {
    _progressController.close();
  }
}
