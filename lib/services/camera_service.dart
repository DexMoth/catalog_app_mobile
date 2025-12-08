import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;

  // инициализация
  Future<void> init() async {
    // получаем все доступные камеры
    final cameras = await availableCameras();

    // берем заднюю камеру
    CameraDescription camera;
    try {
      camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      camera = cameras.first;
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
  }

  // сделать фото
  Future<String> takePicture() async {
    if (_controller == null) {
      throw Exception('Камера не инициализирована. Сначала вызови init()');
    }

    final photo = await _controller!.takePicture();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'photo_$timestamp.jpg';
    final savedPath = '${tempDir.path}/$fileName';

    // копируем в кэш
    final originalFile = File(photo.path);
    if (!originalFile.existsSync()) {
      throw Exception('Файл фото не найден: ${photo.path}');
    }

    await originalFile.copy(savedPath);

    // возвращаем путь к файлу
    return savedPath;
  }

  CameraController? get controller => _controller;

  // освобождаем
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}