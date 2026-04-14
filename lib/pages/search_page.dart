import 'dart:convert';

import 'package:catalog_app_mobile/pages/item_detail_page.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'item_edit_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openSearch();
    });
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: CustomSearchDelegate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Поиск',
          ),
        ],
      ),
      body: const Center(),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final double heightCard = 120;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getItems(searchQuery: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(child: Text('Ничего не найдено'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return Card(
              margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  );
                },
                child: SizedBox(
                  height: heightCard,
                  child: Row(
                    children: [
                      // Изображение
                      SizedBox(
                        width: 120,
                        child: _buildImage(item),
                      ),
                      // Текст и иконки
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Название
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Описание
                              if (item.description != null && item.description!.isNotEmpty)
                                Text(
                                  item.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Иконки действий
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
                                      color: Color.fromARGB(255, 80, 60, 20),
                                    ),
                                    iconSize: 20,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditItemPage(item: item),
                                        ),
                                      ).then((updatedItem) {
                                        if (updatedItem != null) {
                                          // Обновляем результаты
                                          buildResults(context);
                                        }
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color.fromARGB(255, 80, 60, 20),
                                    ),
                                    iconSize: 20,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showDeleteDialog(context, item);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    iconSize: 20,
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
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  // Виджет изображения
  Widget _buildImage(item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      // Проверяем, является ли строка base64
      final isBase64 = item.imagePath!.contains('base64,') ||
          item.imagePath!.startsWith('data:image/') ||
          (item.imagePath!.length > 100 && !item.imagePath!.startsWith('http'));

      if (isBase64) {
        // Для base64 - используем Image.memory
        try {
          final cleanBase64 = item.imagePath!.contains(',')
              ? item.imagePath!.split(',').last
              : item.imagePath!;
          final bytes = base64Decode(cleanBase64);
          return ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image.memory(
              bytes,
              width: 120,
              height: heightCard,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            ),
          );
        } catch (e) {
          return _buildPlaceholder();
        }
      } else {
        // Для URL (если есть)
        return ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Image.network(
            item.imagePath!,
            width: 120,
            height: heightCard,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        );
      }
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: heightCard,
      color: Colors.grey[200],
      child: const Icon(Icons.photo, color: Colors.grey),
    );
  }

  // Диалог удаления
  void _showDeleteDialog(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предмет?'),
        content: Text('Вы уверены, что хотите удалить "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await ApiService().deleteItem(item.id);
              Navigator.pop(context);
              // Обновляем результаты
              buildResults(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}