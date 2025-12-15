import 'dart:math';
import 'dart:math';
import 'package:catalog_app_mobile/pages/item_children_page.dart';
import 'package:catalog_app_mobile/pages/item_edit_page.dart';
import 'package:catalog_app_mobile/pages/search_page.dart';
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

import '../configuration/constants.dart';
import '../models/item.dart';
import '../services/image_service.dart';
import '../widgets/appDrawer.dart';
import 'item_detail_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final ApiService _apiService = ApiService();
  List<Item> _items = [];
  bool _isLoading = true;
  String? _error;

  // создание страницы
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // загрузка вещей без родителя
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.getItems();
      final rootItems = items.where((item) => item.parentId == null).toList();
      // потом сделать эндпоинт
      //print(items);
      setState(() {
        _items = rootItems;
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
        title: const Text('Мои вещи'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => {
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
              )
            },
            tooltip: 'Поиск',
          ),
        ],
      ),
      drawer: const AppDrawer(), // боковое меню
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditItemPage(
                item: null,
              ),
            ),
          ).then((createdItem) {
            if (createdItem != null) {
              _loadItems(); // Обновляем список после создания
            }
          });
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
              onPressed: _loadItems,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('Список пуст. Попробуйте добавить вещь!'),
      );
    }

// список вещей
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secAnimation) =>
                      ItemChildrenPage(parentItem: item),
                  transitionsBuilder: (context, animation, secAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: SizedBox(
              height: heightCard,
              child: Row(
                children: [
                  // Изображение
                  SizedBox(
                    width: 190,
                    child: _buildImage(item),
                  ),
                  // Текст и иконки
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Название
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16), // Отступ
                          // Иконки
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemDetailPage(item: item),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                    Icons.remove_red_eye,
                                    color: Color.fromARGB(255,80,60,20)
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => EditItemPage(item: item)
                                      )
                                  ).then((updatedItem) {
                                    if (updatedItem != null) {
                                      _loadItems();
                                    }
                                  });
                                },
                                icon: const Icon(
                                    Icons.edit,
                                    color: Color.fromARGB(255,80,60,20)
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeleteDialog(item);
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showDeleteDialog(Item item) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Удаление"),
          content: Text("""Вы уверены, что хотите удалить "${item.name}"?"""),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _confirmDelete(item);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        )
    );
  }

  void _confirmDelete(Item item) async {
    try {
      final success = await ApiService().deleteItem(item.id);
      if (success) {
        Navigator.pop(context); // убрираем диалог
        Navigator.pop(context, true); // вернуться назад
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Элемент удален')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  Widget _buildImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return ImageService.buildImageFromPath(
        item.imagePath!,
        width: 190,
        height: heightCard,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.photo, color: Colors.grey[400]),
      );
    }
  }
}