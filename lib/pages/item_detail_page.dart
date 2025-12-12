import 'package:catalog_app_mobile/models/category.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/tag.dart';
import '../services/api_service.dart';
import 'item_edit_page.dart';

class ItemDetailPage extends StatefulWidget  {
  final Item item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage>{
  late Item _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
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
        child: Image.network(
          _currentItem.imagePath ?? 'http://placehold.jp./300x300.png',
          fit: BoxFit.cover,
        ),
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
    final itemCategories = _currentItem.categories ?? [];

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (itemCategories.isEmpty)
            const Text(
              'Категории не указаны',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 1,
              children: [
                ...itemCategories.map((category) {
                  return Chip(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    backgroundColor: Colors.brown.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.brown),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }),
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
                    child: const Icon(
                      Icons.add,
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
        final itemTags = widget.item.tags ?? []; // Теги текущей вещи

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
                        final isSelected = itemTags.contains(tag.id);

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

                      // кнопка добавления
                      IconButton(
                        onPressed: () {
                          print('Добавить тег');
                          _showDialogAddTag(context);
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.brown.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
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
          ),
        );
      },
    );
  }

  // переключение состояния тега
  void _toggleTag(Tag tag) {
    setState(() {
      final currentTags = _currentItem.tags ?? [];

      // Проверяем, привязан ли уже этот тег по id
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
        builder: (context) => AlertDialog(
          title: const Text("Добавление нового тега"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название тега',
              hintText: 'Введите название',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')
            ),
            TextButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    // API
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить')
            )
          ],
        )
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
            final selectedCategories = _currentItem.categories ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Выберите категорию'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategories.any((c) => c.id == category.id);

                        return CheckboxListTile(
                          title: Text(category.name),
                          value: isSelected,
                          onChanged: (selected) {
                            setDialogState(() {
                              final currentCategories = _currentItem.categories ?? [];

                              if (selected == true) {
                                _currentItem.categories = [
                                  ...currentCategories,
                                  category
                                ];
                              } else {
                                _currentItem.categories = currentCategories
                                    .where((c) => c.id != category.id)
                                    .toList();
                              }
                            });
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
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Обновляем основной экран
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
