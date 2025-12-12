import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class ImageService {
  static String? imageFileToBase64(File? imageFile) {
    if (imageFile == null || !imageFile.existsSync()) return null;

    try {
      final bytes = imageFile.readAsBytesSync();
      final base64String = base64Encode(bytes);

      final extension = path.extension(imageFile.path).toLowerCase();
      String mimeType = 'image/jpeg'; // по умолчанию

      if (extension == '.png')
        mimeType = 'image/png';
      else if (extension == '.gif')
        mimeType = 'image/gif';
      else if (extension == '.bmp')
        mimeType = 'image/bmp';
      else if (extension == '.webp') mimeType = 'image/webp';

      // формат data:image/[type];base64,[данные]
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Ошибка конвертации изображения: $e');
      return null;
    }
  }
}