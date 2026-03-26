import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  // Основная папка для изображений
  late final Directory _appDir;

  // Инициализация (вызвать один раз при старте приложения)
  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
  }

  // Сохранить изображение из файла
  Future<String?> saveImageFromFile(File sourceFile, {String? fileName}) async {
    try {
      // Создаем папку для изображений если её нет
      final imagesDir = Directory('${_appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Генерируем имя файла
      final finalFileName = fileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destinationPath = path.join(imagesDir.path, finalFileName);

      // Копируем файл
      final destinationFile = await sourceFile.copy(destinationPath);

      // Возвращаем относительный путь для сохранения в БД
      return 'images/$finalFileName';
    } catch (e) {
      print('Ошибка сохранения изображения: $e');
      return null;
    }
  }

  // Сохранить изображение из байтов
  Future<String?> saveImageFromBytes(Uint8List bytes, {String? fileName}) async {
    try {
      final imagesDir = Directory('${_appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final finalFileName = fileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(imagesDir.path, finalFileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return 'images/$finalFileName';
    } catch (e) {
      print('Ошибка сохранения байтов: $e');
      return null;
    }
  }

  // Загрузить изображение для отображения
  Future<File?> loadImage(String relativePath) async {
    try {
      final fullPath = path.join(_appDir.path, relativePath);
      final file = File(fullPath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  // Удалить изображение
  Future<bool> deleteImage(String relativePath) async {
    try {
      final fullPath = path.join(_appDir.path, relativePath);
      final file = File(fullPath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка удаления изображения: $e');
      return false;
    }
  }
}