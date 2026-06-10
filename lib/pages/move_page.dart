import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';

class MovePage extends StatefulWidget {
  final Item itemToMove;
  final VoidCallback onMoveComplete;

  const MovePage({
    super.key,
    required this.itemToMove,
    required this.onMoveComplete,
  });

  @override
  State<MovePage> createState() => _MovePageState();
}

class _MovePageState extends State<MovePage> {
  List<Item> _folders = [];
  bool _isLoading = true;
  List<Item> _path = [];
  Map<int, List<Item>> _childrenCache = {};

  @override
  void initState() {
    super.initState();
    _loadRootFolders();
  }

  Future<void> _loadRootFolders() async {
    try {
      final items = await ApiService().getItems();
      _folders = items.where((item) =>
      item.parentId == null &&
          item.id != widget.itemToMove.id
      ).toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChildren(Item folder) async {
    if (_childrenCache.containsKey(folder.id)) {
      setState(() {
        _folders = _childrenCache[folder.id]!;
        _path.add(folder);
      });
      return;
    }

    try {
      final children = await ApiService().getChildrenItems(folder.id);
      final filteredChildren = children.where((item) =>
      item.id != widget.itemToMove.id &&
          item.parentId != widget.itemToMove.id
      ).toList();

      _childrenCache[folder.id] = filteredChildren;

      setState(() {
        _folders = filteredChildren;
        _path.add(folder);
      });
    } catch (e) {
      print('Ошибка загрузки детей: $e');
    }
  }

  void _goBack() {
    if (_path.isEmpty) return;

    setState(() {
      _path.removeLast();
      if (_path.isEmpty) {
        _loadRootFolders();
      } else {
        final parent = _path.last;
        _folders = _childrenCache[parent.id] ?? [];
      }
    });
  }

  Future<void> _moveItemHere(Item? targetFolder) async {
    try {
      final newParentId = targetFolder?.id;

      final updatedItem = Item(
        id: widget.itemToMove.id,
        name: widget.itemToMove.name,
        description: widget.itemToMove.description,
        imagePath: widget.itemToMove.imagePath,
        parentId: newParentId,
        category: widget.itemToMove.category,
        tags: widget.itemToMove.tags,
        createdAt: widget.itemToMove.createdAt,
        updatedAt: DateTime.now(),
      );

      await ApiService().updateItem(updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newParentId == null
                  ? 'Перемещено в корень'
                  : 'Перемещено в "${targetFolder?.name}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onMoveComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ImageService.buildImageFromPath(
          item.imagePath!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.folder, color: Colors.grey[400], size: 30),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_path.isEmpty ? 'Перемещение' : _path.last.name),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_path.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _path.clear();
                  _loadRootFolders();
                });
              },
              tooltip: 'В корень',
            ),
        ],
      ),
      body: Column(
        children: [
          // Хлебные крошки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _path.clear();
                      });
                      _loadRootFolders();
                    },
                    child: Text(
                      'Корень',
                      style: TextStyle(
                        color: _path.isEmpty ? Colors.black : Colors.blue,
                        fontWeight: _path.isEmpty ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  ..._path.map((folder) {
                    final isLast = _path.last.id == folder.id;
                    return Row(
                      children: [
                        const Text(' / '),
                        GestureDetector(
                          onTap: () {
                            final index = _path.indexOf(folder);
                            setState(() {
                              _path = _path.sublist(0, index + 1);
                              _folders = _childrenCache[folder.id] ?? [];
                            });
                          },
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              color: isLast ? Colors.black : Colors.blue,
                              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Информация о перемещаемом предмете
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.drive_file_move, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Перемещаем:',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                      Text(
                        widget.itemToMove.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Выберите папку назначения:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),

          // Список папок в виде строк (ListTile)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                ? const Center(child: Text('Папка пуста'))
                : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: _buildImage(folder),
                    title: Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      // При нажатии переходим внутрь папки
                      _loadChildren(folder);
                    },
                    onLongPress: () {
                      // При долгом нажатии перемещаем сюда
                      _moveItemHere(folder);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.brown),
                ),
                child: const Text('Отмена', style: TextStyle(color: Colors.brown)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final targetFolder = _path.isNotEmpty ? _path.last : null;
                  _moveItemHere(targetFolder);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _path.isNotEmpty
                      ? 'Переместить в "${_path.last.name}"'
                      : 'Переместить в корень',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}