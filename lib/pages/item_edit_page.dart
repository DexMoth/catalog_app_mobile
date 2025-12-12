import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:catalog_app_mobile/pages/take_photo_page.dart';
import 'package:catalog_app_mobile/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:gallery_picker/models/media_file.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/gallery_service.dart';

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
  bool _isCreating = false;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  final GalleryService _galleryService = GalleryService();

  @override
  void initState() {
    super.initState();
    _isCreating = widget.item == null;
    _currentItem = widget.item ?? Item.empty(); // если нулл то пустой
    _nameController = TextEditingController(text: _currentItem.name);
    _descriptionController = TextEditingController(text: _currentItem.description);
    _selectedImagePath = _currentItem.imagePath;
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
    String? imageUrl = _selectedImagePath ?? _currentItem.imagePath;

    // является ли это base64 строкой
    bool isBase64 = imageUrl != null &&
        (imageUrl.startsWith('data:image/') ||
            imageUrl.startsWith('base64,') ||
            imageUrl.length > 1000);

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey,
          ),
          child: imageUrl == null
              ? Center(
            child: Icon(
              Icons.photo,
              size: 64,
              color: Colors.grey[400],
            ),
          )
              : isBase64
              ? Image.memory(
            // в байты
            base64Decode(imageUrl.contains(',')
                ? imageUrl.split(',').last
                : imageUrl),
            fit: BoxFit.cover,
          )
              : Image.network(
            imageUrl,
            fit: BoxFit.cover
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Выбрать из галереи
                print('Выбрать из галереи');
                _selectFromGallery();
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Галерея'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
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

    if (_selectedImagePath != null) {
      try {
        // Читаем файл и конвертируем в base64
        final file = File(_selectedImagePath!);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        finalImagePath = base64Image;
      } catch (e) {
        print('Ошибка конвертации изображения: $e');
        finalImagePath = _currentItem.imagePath;
      }
    }

    final updatedItem  = Item(
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
      builder: (context) => AlertDialog(
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
    final files = await GalleryPicker.pickMedia(
      context: context,
      singleMedia: true,
      config: Config(
        mode: Mode.light,
        recents: "Недавние",
        gallery: "Галерея",
        tapPhotoSelect: "Нажмите для выбора",
      ),
    );

    if (files?.isNotEmpty ?? false) {
      final file = await files!.first.file;
      if (file != null) {
        setState(() {
          _selectedImageBytes = file.readAsBytesSync();
          _selectedImagePath = file.path;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    File? _selectedImageFile;

    final photoPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const TakePhotoPage(),
    ),);
    print('Сделать фото');

    // есть фото
    if (photoPath != null && mounted) {
      final imageFile = File(photoPath);
      setState(() {
        _selectedImageFile = imageFile;
        // превьюшка
        _selectedImagePath = photoPath;
      });
    }
  }


  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }
}