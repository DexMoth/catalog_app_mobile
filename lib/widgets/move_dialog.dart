import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class MoveDialog extends StatefulWidget {
  final Item itemToMove;
  final VoidCallback onMoveComplete;

  const MoveDialog({
    super.key,
    required this.itemToMove,
    required this.onMoveComplete,
  });

  @override
  State<MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<MoveDialog> {
  List<Item> _folders = [];
  bool _isLoading = true;
  Item? _selectedFolder;
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.99,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          children: [
            // Заголовок с хлебными крошками
            Row(
              children: [
                if (_path.isNotEmpty)
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    _path.isEmpty ? 'Корень' : _path.last.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            // Хлебные крошки
            if (_path.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                        child: const Text(
                          'Корень',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      ..._path.map((folder) {
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
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            const Divider(),

            // Что перемещаем
            Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.blue),
                title: Text(
                  '${widget.itemToMove.name}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text('Выберите папку назначения:', style: TextStyle(fontSize: 16)),

            // Список папок
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _folders.isEmpty
                  ? const Center(child: Text('Папка пуста'))
                  : SingleChildScrollView(  // ← ОБЕРНУЛИ В SingleChildScrollView
                child: Column(
                  children: _folders.map((folder) {
                    return Card(
                      color: _selectedFolder?.id == folder.id
                          ? Colors.amber[50]
                          : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder.name),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedFolder = folder;
                          });
                        },
                        onLongPress: () {
                          _loadChildren(folder);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Кнопка "Зайти в выбранную папку"
            if (_selectedFolder != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _loadChildren(_selectedFolder!);
                    setState(() {
                      _selectedFolder = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Зайти в "${_selectedFolder!.name}"'),
                ),
              ),

            // Кнопки перемещения
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: (_selectedFolder != null || _path.isNotEmpty)
                      ? _moveItem
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    _selectedFolder != null
                        ? 'Переместить'
                        : _path.isNotEmpty
                        ? 'Переместить'
                        : 'Переместить',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveItem() async {
    try {
      final newParentId = _selectedFolder?.id ?? (_path.isNotEmpty ? _path.last.id : null);

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
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newParentId == null
                ? 'Перемещено в корень'
                : 'Перемещено в "${_selectedFolder?.name ?? _path.last.name}"',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onMoveComplete();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}