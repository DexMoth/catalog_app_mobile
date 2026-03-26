import 'package:catalog_app_mobile/models/category.dart';
import 'package:catalog_app_mobile/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/tag.dart';
import '../services/api_service.dart';
import 'item_edit_page.dart';

class ItemDetailPage extends StatefulWidget  {
  final ApiService? apiService;
  final Item item;

  const ItemDetailPage({super.key, required this.item, this.apiService});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage>{
  final ApiService _apiService = ApiService();
  late Item _currentItem;
  Category? _category;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    if (_currentItem.category != null) {
      final cat = await _apiService.getCategory(_currentItem.category!);
      if (mounted) {
        setState(() {
          _category = cat;
        });
      }
    }
  }

  Widget _buildCategoryWidget() {
    // если не выбрана
    if (_currentItem.category == null) {
      return const Text('Категория не выбрана');
    }

    // если загружается
    if (_category == null) {
      return const SizedBox(height:  14);
    }

    return Text(
      _category!.name,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  @override
  // закрытие
  void dispose() {
    _currentItem.updatedAt = DateTime.now();
    // сохраняем изменения
    if (_hasChanges) {
      _saveChanges();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentItem.name),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditItemPage(item: _currentItem)
                  )
              );
            },
            icon: const Icon(
                Icons.edit,
                color: Colors.white
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // КАРТИНКА
            _buildImageSection(),

            Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    // КАТЕГОРИИ
                    _buildCategories(context),

                    const SizedBox(height: 4),

                    // НАЗВАНИЕ И ОСНОВНАЯ ИНФОРМАЦИЯ
                    _buildBasicInfo(),

                    const SizedBox(height: 10),

                    // ТЕГИ
                    _buildTags(),
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: _buildImagePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_currentItem.imagePath == null || _currentItem.imagePath!.isEmpty) {
      return _buildFallbackImage();
    }

    final imagePath = _currentItem.imagePath!;

    // Проверяем, является ли строка base64
    final isBase64 = imagePath.contains('base64,') ||
        imagePath.startsWith('data:image/') ||
        (imagePath.length > 100 && !imagePath.startsWith('http') && !imagePath.startsWith('/'));

    final bytes = ImageService.decodeBase64(imagePath);

    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
      );
    } else {
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

  Widget _buildBasicInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.brown),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentItem.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (_currentItem.parentId != null) ...[
              Row(
                children: [
                  const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Родительский ID: ${_currentItem.parentId}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'ID: ${_currentItem.id}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // описание
            const Row(
              children: [
                SizedBox(width: 12),
                Text(
                  'Описание',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _currentItem.description ?? 'Нет описания',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            // доп информация
            const Row(
              children: [
                SizedBox(width: 12),
                Text(
                  'Информация',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Создано', '12.01.2024'),
            _buildInfoRow('Обновлено', '15.01.2024'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final itemCategories = _currentItem.category;

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 1,
            children: [
              if (itemCategories != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Текст категории
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
                        child: _buildCategoryWidget(),
                      ),
                      // Крестик для удаления
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentItem.category = null;
                            _category = null;
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(right: 4),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Сообщение если нет категорий
              if (itemCategories == null)
                const Text(
                  'Категория не выбрана',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              // Кнопка добавления категории
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
                    itemCategories == null ? Icons.add : Icons.edit,
                    size: 18,
                    color: Colors.brown,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return FutureBuilder<List<Tag>>(
      future: ApiService().getTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tags = snapshot.data ?? [];
        final itemTags = _currentItem.tags ?? []; // Теги текущей вещи

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.brown),
                    SizedBox(width: 12),
                    Text(
                      'Теги',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tags.isEmpty)
                  const Text(
                    'Теги не указаны',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...tags.map((tag) {
                        final isSelected = itemTags.any((t) => t.id == tag.id);

                        return InkWell(
                          onTap: () => _toggleTag(tag),
                          child: Chip(
                            label: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.brown,
                                ),
                              ),
                            ),
                            // если привязан / не привян
                            backgroundColor: isSelected
                                ? Colors.brown // для привязанных
                                : null,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.brown,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            side: isSelected
                                ? null
                                : BorderSide(color: Colors.brown.withOpacity(0.3)),
                          ),
                        );
                      }).toList(),

                      // кнопка добавления , будет в вкр
                      // IconButton(
                      //   onPressed: () {
                      //     _showDialogAddTag(context);
                      //   },
                      //   icon: Container(
                      //     padding: const EdgeInsets.all(6),
                      //     decoration: BoxDecoration(
                      //       shape: BoxShape.circle,
                      //       border: Border.all(
                      //         color: Colors.brown.withOpacity(0.3),
                      //       ),
                      //     ),
                      //     child: const Icon(
                      //       Icons.add,
                      //       size: 18,
                      //       color: Colors.brown,
                      //     ),
                      //   ),
                      //   padding: EdgeInsets.zero,
                      //   constraints: const BoxConstraints(),
                      // ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    try {
      await ApiService().updateItem(_currentItem);
    } catch (e) {
      print("ошибка");
    }
  }

  // переключение состояния тега
  void _toggleTag(Tag tag) {
    setState(() {
      final currentTags = _currentItem.tags ?? [];

      // Проверяем, привязан ли уже этот тег
      final isTagEnabled = currentTags.any((t) => t.id == tag.id);

      if (isTagEnabled) {
        // удаляем тег если уже привязан
        _currentItem.tags = currentTags
            .where((t) => t.id != tag.id)
            .toList();
      } else {
        // добавляем тег если не привязан
        _currentItem.tags = [...currentTags, tag];
      }
      _hasChanges = true;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDialogAddTag(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isCreating = false;

          return AlertDialog(
            title: const Text("Добавить тег"),
            content: isCreating
                ? const Center(child: CircularProgressIndicator())
                : TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Название тега',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              if (!isCreating)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Введите название')),
                    );
                    return;
                  }

                  setState(() => isCreating = true);

                  try {
                    final newTag = Tag(
                      id: 0,
                      name: newName,
                    );

                    setState(() {
                      final currentTags = _currentItem.tags ?? [];
                      _currentItem.tags = [...currentTags, newTag];
                    });
                    final newTag1 = await ApiService().createTag(newName);
                    // Закрываем диалог
                    Navigator.pop(context);

                  } catch (e) {
                    setState(() => isCreating = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                },
                child: isCreating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Добавить'),
              ),
            ],
          );
        },
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
            final currentCategory = _currentItem.category == null
                ? _currentItem.category
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
                    final isSelected = currentCategory == category.id;

                    return ListTile(
                      title: Text(category.name),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.brown) : null,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            // Если уже выбрана - убираем
                            _currentItem.category = null;
                            _category = null;
                          } else {
                            // Выбираем новую
                            _currentItem.category = category.id;
                            _category = category;
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
                        _currentItem.category = null;
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
}
