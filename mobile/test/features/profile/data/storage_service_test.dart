import 'package:flutter_test/flutter_test.dart';
import 'package:yaro0_mobile/features/profile/data/storage_service.dart';

void main() {
  group('PhotoStorageService - File Format Validation', () {
    test('accepts JPEG files (.jpg)', () {
      expect(isValidFileFormat('/path/to/photo.jpg'), isTrue);
    });

    test('accepts JPEG files (.jpeg)', () {
      expect(isValidFileFormat('/path/to/photo.jpeg'), isTrue);
    });

    test('accepts PNG files (.png)', () {
      expect(isValidFileFormat('/path/to/photo.png'), isTrue);
    });

    test('accepts HEIC files (.heic)', () {
      expect(isValidFileFormat('/path/to/photo.heic'), isTrue);
    });

    test('accepts uppercase extensions', () {
      expect(isValidFileFormat('/path/to/photo.JPG'), isTrue);
      expect(isValidFileFormat('/path/to/photo.JPEG'), isTrue);
      expect(isValidFileFormat('/path/to/photo.PNG'), isTrue);
      expect(isValidFileFormat('/path/to/photo.HEIC'), isTrue);
    });

    test('accepts mixed case extensions', () {
      expect(isValidFileFormat('/path/to/photo.Jpg'), isTrue);
      expect(isValidFileFormat('/path/to/photo.Png'), isTrue);
    });

    test('rejects GIF files', () {
      expect(isValidFileFormat('/path/to/image.gif'), isFalse);
    });

    test('rejects BMP files', () {
      expect(isValidFileFormat('/path/to/image.bmp'), isFalse);
    });

    test('rejects TIFF files', () {
      expect(isValidFileFormat('/path/to/image.tiff'), isFalse);
    });

    test('rejects WebP files', () {
      expect(isValidFileFormat('/path/to/image.webp'), isFalse);
    });

    test('rejects SVG files', () {
      expect(isValidFileFormat('/path/to/image.svg'), isFalse);
    });

    test('rejects non-image files', () {
      expect(isValidFileFormat('/path/to/document.pdf'), isFalse);
      expect(isValidFileFormat('/path/to/file.txt'), isFalse);
      expect(isValidFileFormat('/path/to/video.mp4'), isFalse);
    });

    test('rejects files with no extension', () {
      expect(isValidFileFormat('/path/to/photo'), isFalse);
    });
  });

  group('PhotoStorageService - File Size Validation', () {
    test('accepts files exactly at 10 MB limit', () {
      expect(isValidFileSize(10 * 1024 * 1024), isTrue);
    });

    test('accepts files under 10 MB', () {
      expect(isValidFileSize(5 * 1024 * 1024), isTrue);
      expect(isValidFileSize(1024), isTrue);
      expect(isValidFileSize(0), isTrue);
    });

    test('rejects files over 10 MB', () {
      expect(isValidFileSize(10 * 1024 * 1024 + 1), isFalse);
      expect(isValidFileSize(20 * 1024 * 1024), isFalse);
    });

    test('accepts 1 byte file', () {
      expect(isValidFileSize(1), isTrue);
    });

    test('rejects file at 11 MB', () {
      expect(isValidFileSize(11 * 1024 * 1024), isFalse);
    });
  });

  group('PhotoStorageService - Max Photos Limit', () {
    test('allows upload when user has 0 photos', () {
      expect(canAddPhoto(0), isTrue);
    });

    test('allows upload when user has 5 photos', () {
      expect(canAddPhoto(5), isTrue);
    });

    test('rejects upload when user already has 6 photos', () {
      expect(canAddPhoto(6), isFalse);
    });

    test('rejects upload when user has more than 6 photos', () {
      expect(canAddPhoto(7), isFalse);
    });
  });

  group('PhotoValidationException', () {
    test('toString includes message', () {
      const exception = PhotoValidationException('Test error');
      expect(
        exception.toString(),
        'PhotoValidationException: Test error',
      );
    });

    test('message is accessible', () {
      const exception = PhotoValidationException('File too large');
      expect(exception.message, 'File too large');
    });
  });

  group('PhotoUploadException', () {
    test('toString includes message', () {
      const exception = PhotoUploadException('Upload failed');
      expect(
        exception.toString(),
        'PhotoUploadException: Upload failed',
      );
    });

    test('message is accessible', () {
      const exception = PhotoUploadException('Network error');
      expect(exception.message, 'Network error');
    });

    test('retainedImage defaults to null', () {
      const exception = PhotoUploadException('Error');
      expect(exception.retainedImage, isNull);
    });
  });

  group('Constants', () {
    test('maxPhotosPerUser is 6', () {
      expect(maxPhotosPerUser, 6);
    });

    test('maxFileSizeBeforeCompression is 10 MB', () {
      expect(maxFileSizeBeforeCompression, 10 * 1024 * 1024);
    });

    test('maxFileSizeAfterCompression is 1 MB', () {
      expect(maxFileSizeAfterCompression, 1 * 1024 * 1024);
    });

    test('maxResolution is 1080', () {
      expect(maxResolution, 1080);
    });

    test('supportedFormats contains expected formats', () {
      expect(supportedFormats, contains('.jpg'));
      expect(supportedFormats, contains('.jpeg'));
      expect(supportedFormats, contains('.png'));
      expect(supportedFormats, contains('.heic'));
      expect(supportedFormats.length, 4);
    });
  });
}
