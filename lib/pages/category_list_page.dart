import 'dart:math';
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../widgets/appDrawer.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final ApiService _apiService = ApiService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  // создание страницы
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _apiService.getCategories();
      //print(categories);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(), // боковое меню
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog();
        },
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      )
    );
    throw UnimplementedError();
  }

  Widget _buildBody() {
    if(_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка: $_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('Список пуст. Попробуйте добавить тег!'),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () {
                      _showEditDialog(context, category);
                    },
                    icon: const Icon(Icons.edit, color: Color.fromARGB(255,80,60,20),)
                ),
                IconButton(
                    onPressed: () {
                      _showDeleteDialog(category);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red,)
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // удаление
  void _showDeleteDialog(Category category) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Удалить категорию?"),
          content: Text("""Вы уверены, что хотите удалить категорию "${category.name}"?"""),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                // API
                await _apiService.deleteCategory(category.id);
                setState(() {
                  _categories.removeWhere((t) => t.id == category.id);
                });
                Navigator.pop(context);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ));
  }

  // редактирование
  void _showEditDialog(BuildContext context, Category category) {
    final TextEditingController controller = TextEditingController(text: category.name);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Редактирование категории"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название категории',
              hintText: 'Введите новое название',
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
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    // API
                    final newCategory = Category(id: category.id, name: newName);
                    await _apiService.updateCategory(newCategory);
                    setState(() {
                      final index = _categories.indexWhere((t) => t.id == category.id);
                      if (index != -1) {
                        _categories[index] = newCategory;
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить')
            )
          ],
        ));
  }

  void _showAddDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Добавить категорию"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название категории',
            hintText: 'Введите название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                  final newCategory = await _apiService.createCategory(newName);

                  setState(() {
                    _categories.add(newCategory);
                    _categories.sort((a, b) => a.name.compareTo(b.name));
                  });

                  Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}