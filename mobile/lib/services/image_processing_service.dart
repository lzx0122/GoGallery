import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  // Background Removal
  static Future<Uint8List?> removeBackground(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        debugPrint('Image file does not exist');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();

      try {
        await BackgroundRemover.instance.initializeOrt();
      } catch (_) {}

      // Result is ui.Image
      final ui.Image result = await BackgroundRemover.instance.removeBg(
        imageBytes,
      );

      // Convert ui.Image to PNG bytes
      final byteData = await result.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error removing background: $e');
      return null;
    }
  }

  static Future<File> saveBytesToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
