import 'package:flutter/material.dart';

import '../configuration/constants.dart';
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
  final ApiService _apiService = ApiService();

  List<Item> _folders = [];
  final List<Item> _path = [];
  final Map<int, List<Item>> _childrenCache = {};

  bool _isLoading = true;
  String? _error;

  Item? get _currentFolder => _path.isEmpty ? null : _path.last;

  @override
  void initState() {
    super.initState();
    _loadRootFolders();
  }

  Future<void> _loadRootFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.getItems();

      final roots = items.where((item) {
        return item.parentId == null && item.id != widget.itemToMove.id;
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;

      setState(() {
        _folders = roots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChildren(Item folder) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_childrenCache.containsKey(folder.id)) {
      final cached = _childrenCache[folder.id] ?? [];

      setState(() {
        _folders = cached;
        _path.add(folder);
        _isLoading = false;
      });
      return;
    }

    try {
      final children = await _apiService.getChildrenItems(folder.id);

      final filteredChildren = children.where((item) {
        return item.id != widget.itemToMove.id &&
            item.parentId != widget.itemToMove.id;
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _childrenCache[folder.id] = filteredChildren;

      if (!mounted) return;

      setState(() {
        _folders = filteredChildren;
        _path.add(folder);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goBackInFolders() async {
    if (_path.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _path.removeLast();
      _isLoading = true;
      _error = null;
    });

    if (_path.isEmpty) {
      await _loadRootFolders();
    } else {
      final parent = _path.last;
      final cached = _childrenCache[parent.id];

      if (cached != null) {
        setState(() {
          _folders = cached;
          _isLoading = false;
        });
      } else {
        await _loadChildren(parent);
      }
    }
  }

  Future<void> _moveItemHere() async {
    final targetFolder = _currentFolder;
    final newParentId = targetFolder?.id;

    // Если предмет уже находится здесь — не отправляем лишний запрос
    if (widget.itemToMove.parentId == newParentId) {
      _showSnackBar(
        newParentId == null
            ? 'Предмет уже находится в корне'
            : 'Предмет уже находится в этой папке',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
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

      await _apiService.updateItem(updatedItem);

      if (!mounted) return;

      widget.onMoveComplete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newParentId == null
                ? '«${widget.itemToMove.name}» перемещено в корень'
                : '«${widget.itemToMove.name}» перемещено в «${targetFolder!.name}»',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Ошибка перемещения: $e');
    }
  }

  void _goToPathIndex(int index) {
    // index == -1 означает корень
    if (index == -1) {
      setState(() {
        _path.clear();
      });
      _loadRootFolders();
      return;
    }

    final folder = _path[index];

    setState(() {
      _path.removeRange(index + 1, _path.length);
      _folders = _childrenCache[folder.id] ?? [];
    });
  }

  void _showSnackBar(
      String message, {
        Color backgroundColor = Colors.red,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  String _currentLocationTitle() {
    if (_currentFolder == null) return 'Корень';
    return _currentFolder!.name;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = _currentLocationTitle();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Перемещение'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackInFolders,
        ),
        actions: [
          if (_path.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'В корень',
              onPressed: () => _goToPathIndex(-1),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTopPanel(currentLocation),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(currentLocation),
    );
  }

  Widget _buildTopPanel(String currentLocation) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMovingItemCard(),
            const SizedBox(height: 12),
            _buildBreadcrumbs(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.folder_open,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Текущая папка: $currentLocation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovingItemCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _buildSmallItemImage(widget.itemToMove),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Перемещаем',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.itemToMove.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.drive_file_move_outline,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBreadcrumbChip(
            label: 'Корень',
            isSelected: _path.isEmpty,
            onTap: () => _goToPathIndex(-1),
          ),
          for (int i = 0; i < _path.length; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 18,
              ),
            ),
            _buildBreadcrumbChip(
              label: _path[i].name,
              isSelected: i == _path.length - 1,
              onTap: () => _goToPathIndex(i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.brown : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.brown),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildHintCard(),
        Expanded(
          child: _folders.isEmpty ? _buildEmptyState() : _buildFolderList(),
        ),
      ],
    );
  }

  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.brown, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Нажмите на папку, чтобы открыть её. Кнопка снизу переместит предмет в текущую папку.',
              style: TextStyle(
                color: Colors.brown,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _buildFolderTile(folder);
      },
    );
  }

  Widget _buildFolderTile(Item folder) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _loadChildren(folder),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildFolderImage(folder),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  folder.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ImageService.buildImageFromPath(
          item.imagePath!,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.folder_rounded,
        color: Colors.brown,
        size: 34,
      ),
    );
  }

  Widget _buildSmallItemImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageService.buildImageFromPath(
          item.imagePath!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                color: Colors.brown,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'В этой папке нет вложенных папок',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Вы всё равно можете переместить предмет сюда — используйте кнопку внизу.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 58),
            const SizedBox(height: 14),
            const Text(
              'Не удалось загрузить папки',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _path.isEmpty
                  ? _loadRootFolders
                  : () => _loadChildren(_path.last),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String currentLocation) {
    final isSameLocation = widget.itemToMove.parentId == _currentFolder?.id;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.brown),
                  foregroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isSameLocation ? null : _moveItemHere,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.drive_file_move_outline),
                label: Text(
                  _currentFolder == null
                      ? 'Переместить в корень'
                      : 'Переместить сюда',
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