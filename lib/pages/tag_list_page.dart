import 'dart:math';

import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

import '../models/tag.dart';
import '../widgets/appDrawer.dart';

class TagListPage extends StatefulWidget {
  final ApiService? apiService;

  const TagListPage({super.key, this.apiService});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  final ApiService _apiService = ApiService();
  List<Tag> _tags = [];
  bool _isLoading = true;
  String? _error;

  // создание страницы
  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tags = await _apiService.getTags();
      //print(tags);
      setState(() {
        _tags = tags;
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
        title: const Text('Теги'),
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
              onPressed: _loadTags,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_tags.isEmpty) {
      return const Center(
        child: Text('Список пуст. Попробуйте добавить тег!'),
      );
    }

    return ListView.builder(
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.local_offer),
            title: Text(
              tag.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () {
                      _showEditDialog(context, tag);
                    },
                    icon: const Icon(Icons.edit, color: Color.fromARGB(255,80,60,20),)
                ),
                IconButton(
                    onPressed: () {
                      _showDeleteDialog(tag);
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

  // удаление тега
  void _showDeleteDialog(Tag tag) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Удалить тег?"),
          content: Text("""Вы уверены, что хотите удалить тег "${tag.name}"?"""),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            TextButton(
                onPressed: () async {
                  // API
                  await _apiService.deleteTag(tag.id);
                  setState(() {
                    _tags.removeWhere((t) => t.id == tag.id);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Удалить', style: TextStyle(color: Colors.red),
                ),
            ),
          ],
        )
    );
  }

  // редактирование тега
  void _showEditDialog(BuildContext context, Tag tag) {
    final TextEditingController controller = TextEditingController(text: tag.name);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Редактирование тега"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название тега',
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
                    final newTag = Tag(id: tag.id, name: newName);
                    await _apiService.updateTag(newTag);
                    setState(() {
                      final index = _tags.indexWhere((t) => t.id == tag.id);
                      if (index != -1) {
                        _tags[index] = newTag;
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить')
            )
          ],
        )
    );
  }

  void _showAddDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Добавить тег"),
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
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                try {
                  Navigator.pop(context);

                  final newTag = await _apiService.createTag(newName);

                  if (mounted) {
                    setState(() {
                      _tags.add(newTag);
                      _tags.sort((a, b) => a.name.compareTo(b.name));
                    });
                  }

                  await Future.delayed(const Duration(milliseconds: 300));

                  if (mounted) {
                    setState(() {
                    });
                  }

                } catch (e) {
                  // Показываем ошибку
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}