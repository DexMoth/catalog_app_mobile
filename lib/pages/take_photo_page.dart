import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';

class TakePhotoPage extends StatefulWidget {
  const TakePhotoPage({super.key});

  @override
  State<TakePhotoPage> createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends State<TakePhotoPage> {
  final CameraService _camera = CameraService();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _camera.init();
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      print('Ошибка камеры: $e');
    }
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сделать фото'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final controller = _camera.controller;
    if (controller == null) {
      return const Center(
        child: Text('Камера не доступна', style: TextStyle(color: Colors.white)),
      );
    }

    return Column(
      children: [
        // Превью камеры
        Expanded(
          child: CameraPreview(controller),
        ),

        // Кнопка съемки
        Container(
          padding: const EdgeInsets.all(20),
          child: FloatingActionButton(
            onPressed: _takePhoto,
            backgroundColor: Colors.white,
            child: const Icon(Icons.camera, color: Colors.black, size: 36),
          ),
        ),
      ],
    );
  }

  Future<String?> _takePhoto() async {
    try {
      final imagePath = await _camera.takePicture();
      // Возвращаем путь к фото
      Navigator.pop(context, imagePath);
    } catch (e) {
      print('Ошибка фото: $e');
    }
  }
}