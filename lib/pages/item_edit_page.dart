import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:catalog_app_mobile/pages/take_photo_page.dart';
import 'package:catalog_app_mobile/services/camera_service.dart';
import 'package:flutter/material.dart';
// import 'package:gallery_picker/gallery_picker.dart';
// import 'package:gallery_picker/models/media_file.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/gallery_service.dart';
import 'gallery_page.dart';

class EditItemPage extends StatefulWidget {
  final Item? item;

  const EditItemPage({super.key, this.item});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late Item _currentItem;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedImagePath;
  String? _selectedImageBase64;
  bool _isCreating = false;

  // final GalleryService _galleryService = GalleryService();

  @override
  void initState() {
    super.initState();
    _isCreating = widget.item == null;
    _currentItem = widget.item ?? Item.empty(); // если нулл то пустой
    _nameController = TextEditingController(text: _currentItem.name);
    _descriptionController = TextEditingController(text: _currentItem.description);

    if (_currentItem.imagePath != null && _currentItem.imagePath!.isNotEmpty) {
      _selectedImageBase64 = _currentItem.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreating ? 'Создание' : 'Редактирование'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // КАРТИНКА
            _buildImageSection(),

            const SizedBox(height: 24),

            // НАЗВАНИЕ
            _buildNameField(),

            const SizedBox(height: 16),

            // ОПИСАНИЕ
            _buildDescriptionField(),

            const SizedBox(height: 32),

            // КНОПКИ СОХРАНЕНИЯ/ОТМЕНЫ
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey,
          ),
          child: _buildImagePreview(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                print('Выбрать из галереи');
                _selectFromGallery();
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Галерея'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                print('Сделать снимок');
                _takePhoto();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Камера'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_selectedImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Ошибка загрузки файла: $error');
            return _buildFallbackImage();
          },
        ),
      );
    }

    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      return _buildBase64Image(_selectedImageBase64!);
    }

    // Если нет изображения
    return _buildFallbackImage();
  }

  Widget _buildBase64Image(String base64String) {
    try {
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      final bytes = base64Decode(cleanBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      print('Ошибка декодирования base64: $e');
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.photo,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Название вещи',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Введите название',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Введите описание вещи...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.brown),
            ),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.brown),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Сохранить'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showErrorDialog('Введите название вещи');
      return;
    }

    // картинка
    String? finalImagePath = _currentItem.imagePath;

    //если новое фото
    if (_selectedImagePath != null) {
      try {
        // Читаем файл и конвертируем в base64
        final file = File(_selectedImagePath!);
        if (await file.exists()) {
          final base64Image = ImageService.imageFileToBase64(file);
          if (base64Image != null) {
            finalImagePath = base64Image;
            _selectedImageBase64 = base64Image;
          } else {
            throw Exception('Не удалось конвертировать изображение');
          }
        }
      } catch (e) {
        print('Ошибка конвертации изображения: $e');
        finalImagePath = _currentItem.imagePath;
      }
    }

    final updatedItem = Item(
      id: _isCreating ? 0 : _currentItem.id,
      name: newName,
      description: _descriptionController.text.trim(),
      imagePath: finalImagePath,
      parentId: _currentItem.parentId,
      categories: _currentItem.categories,
      tags: _currentItem.tags,
    );

    try {
      Item savedItem;

      if (_isCreating) {
        savedItem = await ApiService().createItem(updatedItem);
      } else {
        savedItem = await ApiService().updateItem(updatedItem);
      }
      // возвращаем на предыдущий экран
      Navigator.pop(context, savedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изменения сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Ошибка сохранения: $e');
    } finally {
      //if (mounted) {
      //setState(() {
      //  _isLoading = false;
      //});
      // }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Ошибка'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _selectFromGallery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GalleryPage()),
    );

    // путь
    if (result != null && result is String) {
      setState(() {
        _selectedImagePath = result;
      });
    }
  }

  Future<void> _takePhoto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TakePhotoPage()),
    );

    // путь к фото
    if (result != null && result is String) {
      setState(() {
        _selectedImagePath = result;
      });
    }
  }
}