import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TakePhotoPage extends StatefulWidget {

  const TakePhotoPage({super.key});

  @override
  State<TakePhotoPage> createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends State<TakePhotoPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;

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
      body: Column(
        children: [
          // Предпросмотр фото
          Expanded(
            child: _buildPreview(),
          ),

          // Кнопка съемки
          _buildCaptureButton(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_capturedImage != null) {
      // Показываем сделанное фото
      return Center(
        child: Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.contain,
        ),
      );
    } else {
      // Простой заглушка для камеры
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Наведите камеру на объект',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCaptureButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка повторной съемки (если фото уже сделано)
          if (_capturedImage != null)
            FloatingActionButton(
              onPressed: _retakePhoto,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.replay, color: Colors.white, size: 30),
            ),

          // Кнопка съемки
          FloatingActionButton(
            onPressed: _takePhoto,
            backgroundColor: Colors.white,
            child: const Icon(Icons.camera, color: Colors.black, size: 36),
          ),

          // Кнопка сохранения (если фото уже сделано)
          if (_capturedImage != null)
            FloatingActionButton(
              onPressed: () => Navigator.pop(context, _capturedImage!.path),
              backgroundColor: Colors.green,
              child: const Icon(Icons.check, color: Colors.white, size: 30),
            ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = photo;
        });
      }
    } catch (e) {
      print('Ошибка при съемке фото: $e');
      _showErrorSnackbar('Ошибка при съемке фото');
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}