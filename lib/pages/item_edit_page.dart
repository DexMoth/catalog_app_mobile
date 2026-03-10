import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:catalog_app_mobile/pages/take_photo_page.dart';
import 'package:catalog_app_mobile/services/camera_service.dart';
import 'package:flutter/material.dart';
// import 'package:gallery_picker/gallery_picker.dart';
// import 'package:gallery_picker/models/media_file.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/image_classifier_service .dart';
import '../services/image_service.dart';
import 'gallery_page.dart';

class EditItemPage extends StatefulWidget {
  final Item? item;
  final int? parentId;

  const EditItemPage({super.key, this.item, this.parentId});

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
  // иишка
  late ImageClassifierService _classifierService;
  Category? _suggestedCategory;
  // категории
  bool _hasChanges = false; // Флаг изменений для категории

  // final GalleryService _galleryService = GalleryService();

  @override
  void initState() {
    super.initState();
    _isCreating = widget.item == null;
    _classifierService = ImageClassifierService();

    // если передан parentId
    if (_isCreating && widget.parentId != null) {
      _currentItem = Item.empty();
      _currentItem.parentId = widget.parentId;
    } else {
      // Редактируем существующую или создаем без родителя
      _currentItem = widget.item ?? Item.empty();
    }

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
    _classifierService = ImageClassifierService();
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

            const SizedBox(height: 8),

            _buildCategories(context),
            _buildCategorySuggestionWidget(),
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
      // предложение категорий
      await _findCategoryForImage(File(result));
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
      // предложение категорий
      await _findCategoryForImage(File(result));
    }
  }

  Widget _buildCategories(BuildContext context) {
    final itemCategories = _currentItem.categories ?? [];

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 1,
            children: [

              if (itemCategories.isNotEmpty)
                Chip(
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          itemCategories.first.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            // Удаляем категорию при нажатии на крестик
                            setState(() {
                              _currentItem.categories = [];
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.brown.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.brown),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              if (itemCategories.isEmpty)
                const Text(
                  'Категория не выбрана',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              IconButton(
                onPressed: () {
                  _showDialogAddCategory(context);
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.brown.withOpacity(0.3)),
                  ),
                  child: Icon(
                    itemCategories.isEmpty ? Icons.add : Icons.edit,
                    size: 18,
                    color: Colors.brown,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDialogAddCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Category>>(
          future: ApiService().getCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            final currentCategory = _currentItem.categories?.isNotEmpty == true
                ? _currentItem.categories!.first
                : null;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return AlertDialog(
              title: const Text('Выберите категорию'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = currentCategory?.id == category.id;

                    return ListTile(
                      title: Text(category.name),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.brown) : null,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            // Если уже выбрана - убираем
                            _currentItem.categories = [];
                          } else {
                            // Выбираем новую
                            _currentItem.categories = [category];
                          }
                          _hasChanges = true;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                if (currentCategory != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentItem.categories = [];
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Убрать категорию',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _findCategoryForImage(File image) async {
    final category = await _classifierService.findCategory(image);

    if (category != null && mounted) {
      setState(() => _suggestedCategory = category);

      setState(() {
        _currentItem.categories = [category];
        _hasChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выбрана категория: ${category.name}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCategorySuggestionWidget() {
    if (_suggestedCategory == null) return SizedBox.shrink();

    final current = _currentItem.categories?.firstOrNull;
    final isSelected = current?.id == _suggestedCategory!.id;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: Colors.brown),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Предложена категория: "${_suggestedCategory!.name}"',
              style: TextStyle(color: Colors.brown),
            ),
          ),
          if (!isSelected)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentItem.categories = [_suggestedCategory!];
                  _hasChanges = true;
                });
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('Выбрать', style: TextStyle(color: Colors.brown)),
            ),
        ],
      ),
    );
  }
}