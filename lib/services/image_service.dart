import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/box_fit.dart';
import 'package:flutter/src/widgets/framework.dart';
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

  static String cleanBase64(String base64String) {
    if (base64String.contains('base64,')) {
      return base64String.split('base64,').last;
    } else if (base64String.contains(',')) {
      return base64String.split(',').last;
    }
    return base64String;
  }

  static Uint8List? decodeBase64(String base64String) {
    try {
      final clean = cleanBase64(base64String);
      return base64Decode(clean);
    } catch (e) {
      print('Ошибка декодирования base64: $e');
      return null;
    }
  }

  static bool isBase64Image(String? imageString) {
    if (imageString == null || imageString.isEmpty) return false;

    return imageString.contains('base64,') ||
        imageString.startsWith('data:image/') ||
        (imageString.length > 100 &&
            !imageString.startsWith('http') &&
            !imageString.startsWith('/'));
  }

  static Widget buildImageFromPath(
      String? imagePath, {
        double? width,
        double? height,
        BoxFit fit = BoxFit.cover,
      }) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildErrorWidget();
    }

    // Base64 изображение
    if (isBase64Image(imagePath)) {
      return buildBase64Image(
        imagePath,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Локальный файл
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: fit,
    );
  }

  static Widget buildBase64Image(
      String base64String, {
        double? width,
        double? height,
        BoxFit fit = BoxFit.cover,
      }) {
    String clean = cleanBase64(base64String);
    final bytes = base64Decode(clean);
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
    );
  }

  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}