import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

/// Platform-agnostic image picking service
/// Handles differences between mobile (image_picker) and web (file_picker)
class ImageService {
  /// Pick a single image from gallery/file system
  /// Returns image bytes or null if cancelled
  static Future<Uint8List?> pickImage() async {
    try {
      if (kIsWeb) {
        // Web: Use file picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          return result.files.first.bytes;
        }
      } else {
        // Mobile: Use image_picker (conditionally imported in calling code)
        // This is handled by the caller with conditional imports
        throw UnimplementedError(
          'Use image_picker package for mobile platforms',
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  /// Pick multiple images from gallery/file system
  /// Returns list of image bytes
  static Future<List<Uint8List>> pickMultipleImages() async {
    final List<Uint8List> images = [];

    try {
      if (kIsWeb) {
        // Web: Use file picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null) {
          for (final file in result.files) {
            if (file.bytes != null) {
              images.add(file.bytes!);
            }
          }
        }
      } else {
        // Mobile: Use image_picker (handled by caller)
        throw UnimplementedError(
          'Use image_picker package for mobile platforms',
        );
      }
    } catch (e) {
      print('Error picking multiple images: $e');
    }

    return images;
  }

  /// Check if camera is available (web doesn't support camera access this way)
  static bool get isCameraAvailable => !kIsWeb;
}
