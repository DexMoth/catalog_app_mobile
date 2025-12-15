import 'package:flutter/material.dart';

import '../configuration/constants.dart';
import '../models/item.dart';
import '../../services/api_service.dart';
import '../services/image_service.dart';
import '../widgets/appDrawer.dart';
import 'item_detail_page.dart';
import 'item_edit_page.dart';
import 'item_list_page.dart';

class ItemChildrenPage extends StatefulWidget {
  final Item parentItem;
  final List<Item>? breadcrumbs; // хлебные крошки

  const ItemChildrenPage({super.key, required this.parentItem, this.breadcrumbs});

  @override
  State<ItemChildrenPage> createState() => _ItemChildrenPageState();
}

class _ItemChildrenPageState extends State<ItemChildrenPage> {
  final ApiService _apiService = ApiService();
  List<Item> _children = [];
  bool _isLoading = true;

  // что перемещать
  Item? _itemToMove;

  // id нового родителя
  int? _targetParentId;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final children = await _apiService.getChildrenItems(widget.parentItem.id);

      setState(() {
        _children = children;
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
          title: Text(widget.parentItem.name),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(), // боковое меню
        body: Column(
          children: [
            _buildBreadcrumbs(), // хлебные крошки
            _buildParent(), // родитель
            Container( // отступ
              height: 1,
            ),
            Expanded(
              child: _buildChildren(), // дети
            ),
          ],
        ),
        floatingActionButton: _itemToMove != null
            ? _buildMoveButtons()
            : FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditItemPage(
                      item: null,
                      parentId: widget.parentItem.id,
                    ),
              ),
            ).then((createdItem) {
              if (createdItem != null) {
                _loadChildren();
              }
            });
          },
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        )
    );
  }

  // метод для хлебных крошек (полного пути)
  Widget _buildBreadcrumbs() {
    // создаем путь
    final breadcrumbs = widget.breadcrumbs ?? [];
    final currentBreadcrumbs = [...breadcrumbs, widget.parentItem];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Главная страница
          _buildBreadcrumbItem(
            text: 'Главная',
            isLast: false,
            onTap: () {
              // Возвращаемся на главную
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ItemListPage()),
                    (route) => false,
              );
            },
          ),

          // Разделитель
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ),

          // Промежуточные элементы
          ..._buildBreadcrumbItems(currentBreadcrumbs),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(List<Item> breadcrumbs) {
    final widgets = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      final item = breadcrumbs[i];
      final isLast = i == breadcrumbs.length - 1;

      widgets.add(
        _buildBreadcrumbItem(
          text: item.name,
          isLast: isLast,
          onTap: isLast ? null : () {
            // Находим индекс текущего элемента и обрезаем массив
            final newBreadcrumbs = breadcrumbs.sublist(0, i);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ItemChildrenPage(
                      parentItem: item,
                      breadcrumbs: newBreadcrumbs,
                    ),
              ),
            );
          },
        ),
      );

      // Добавляем разделитель, если не последний
      if (!isLast) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildBreadcrumbItem({
    required String text,
    required bool isLast,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isLast ? Colors.brown : Colors.blue,
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
          decoration: isLast ? null : TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildParent() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.parentItem.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.parentItem.name.length > 20 ? 12 : 16,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, size: 20),
                  onPressed: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ItemDetailPage(item: widget.parentItem),
                        ),
                      ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () =>
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditItemPage(item: widget.parentItem)
                          )
                      ).then((_) => _loadChildren()),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildChildren() {
    return ListView.builder(
      itemCount: _children.length,
      itemBuilder: (context, index) {
        final item = _children[index];
        return Card(
          margin: const EdgeInsets.fromLTRB(15, 8, 8, 8),
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
                  transitionsBuilder: (context, animation, secAnimation,
                      child) {
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
            onLongPress: () {
              _startMovingItem(item);
            },
            child: SizedBox(
              height: heightCard,
              child: Row(
                children: [
                  // Изображение
                  SizedBox(
                    width: 140,
                    child: _buildImage(item),
                  ),
                  // Текст и иконки
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Название
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: item.name.length > 20
                                  ? 12
                                  : 16, // уменьшаем на 4 если больше 22 символов
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Иконки
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailPage(item: item),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                    Icons.remove_red_eye,
                                    color: Color.fromARGB(255, 80, 60, 20)
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EditItemPage(item: item, parentId: widget.parentItem.id,)
                                      )
                                  ).then((updatedItem) {
                                    if (updatedItem != null) {
                                      _loadChildren();
                                    }
                                  });
                                },
                                icon: const Icon(
                                    Icons.edit,
                                    color: Color.fromARGB(255, 80, 60, 20)
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeleteDialog(item);
                                },
                                icon: const Icon(
                                    Icons.delete, color: Colors.red),
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

  void _showDeleteDialog(Item item) {
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text("Удаление"),
              content: Text(
                  """Вы уверены, что хотите удалить "${item.name}"?"""),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    // API
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Удалить', style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
    );
  }

  void _startMovingItem(Item item) {
    setState(() {
      _itemToMove = item;
    });
  }

  Widget _buildMoveButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // кнопка перемещения
        FloatingActionButton(
          onPressed: () {
            _moveItemHere(null);
          },
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          child: const Icon(Icons.drive_file_move),
        ),
        const SizedBox(height: 10),
        // Кнопка отмены
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _itemToMove = null;
            });
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.close),
        ),
      ],
    );
  }

  // переместить в этого родителя
  Future<void> _moveItemHere(int? newParentId) async {
    if (_itemToMove == null) return;

    // меняем родителя
    final updatedItem = Item(
      id: _itemToMove!.id,
      name: _itemToMove!.name,
      description: _itemToMove!.description,
      imagePath: _itemToMove!.imagePath,
      parentId: newParentId,
      categories: _itemToMove!.categories,
      tags: _itemToMove!.tags,
    );

    try {
      await ApiService().updateItem(updatedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_itemToMove!.name}" перемещен'),
          backgroundColor: Colors.green,
        ),
      );

      //обновляем список
      setState(() {
        _itemToMove = null;
      });
      _loadChildren();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка перемещения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}