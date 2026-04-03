import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';


class StatisticPage extends StatefulWidget {
  final ApiService? apiService;

  const StatisticPage({super.key, this.apiService});

  @override
  State<StatefulWidget> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final ApiService _apiService = ApiService();
  List<Category> _categories = [];
  List<Item> _items = [];
  bool _isLoading = true;
  String? _error;

  // создание страницы
  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {

    final Map<String, int> categoryCount = {};
    final Map<String, Color> categoryColors = {};

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
    ];

    // подсчет предметов в каждой категории
    final categoryMap = {for (var cat in _categories) cat.id: cat};

    for (var item in _items) {
      if (item.category == null) continue;

      final category = categoryMap[item.category];
      if (category == null) continue;

      final catName = category.name;
      categoryCount[catName] = (categoryCount[catName] ?? 0) + 1;

      if (!categoryColors.containsKey(catName)) {
        final index = categoryColors.length;
        categoryColors[catName] = colors[index % colors.length];
      }
    }

    // загрузка
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // если нет данных
    if (categoryCount.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Нет данных для отображения'),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "Популярные категории",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),

              // Круговой график
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildSections(categoryCount, categoryColors),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Легенда (список категорий)
              ...categoryCount.entries.map((entry) {
                return Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: categoryColors[entry.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.key}: ${entry.value} шт.'),
                  ],
                );
              }),

              const SizedBox(height: 30),

              _buildPopularTags(),
              _buildActiveMonth(),
              const SizedBox(height: 30),
              _buildHotZones(),
              _buildEmptyCategories(),
            ],
          ),
        )
    );
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.getItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _error = null;
    });

    try {
      final categ = await _apiService.getCategories();
      setState(() {
        _categories = categ;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  List<PieChartSectionData> _buildSections(
      Map<String, int> data,
      Map<String, Color> colors,
      ) {
    final total = data.values.fold(0, (sum, count) => sum + count);

    return data.entries.map((entry) {
      final percent = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '$percent%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPopularTags() {
    final Map<String, int> tagCount = {};

    for (var item in _items) {
      if (item.tags != null) {
        for (var tag in item.tags!) {
          tagCount[tag.name] = (tagCount[tag.name] ?? 0) + 1;
        }
      }
    }

    if (tagCount.isEmpty) {
      return const Text('Нет тегов');
    }

    // cортируем по убыванию и берем топ-5
    final sortedTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTags = sortedTags.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Популярные теги",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ...topTags.map((entry) {
          final percent = (entry.value / _items.length * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.brown,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${entry.key}'),
                ),
                Text(
                  '${entry.value} (${percent}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActiveMonth() {
    if (_items.isEmpty) {
      return const Text('Нет данных');
    }

    // группируем по месяцам
    final Map<String, int> monthCount = {};

    for (var item in _items) {
      final month = '${item.createdAt.month}.${item.createdAt.year}';
      monthCount[month] = (monthCount[month] ?? 0) + 1;
    }

    // месяц с максимумом
    final maxEntry = monthCount.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    const months = [
      'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
      'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
    ];

    final monthParts = maxEntry.key.split('.');
    final monthNum = int.parse(monthParts[0]) - 1;
    final year = monthParts[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Больше всего добавлено вещей в месяце:",
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          '${months[monthNum]} $year года — ${maxEntry.value} шт.',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildHotZones() {
    final Map<Item, int> childrenCount = {};

    for (var item in _items) {
      childrenCount[item] = 0;
    }

    for (var item in _items) {
      if (item.parentId != null) {
        final parent = _items.firstWhere(
              (i) => i.id == item.parentId,
          orElse: () => Item.empty(),
        );
        if (parent.id != 0) {
          childrenCount[parent] = (childrenCount[parent] ?? 0) + 1;
        }
      }
    }

    // Убираем предметы без потомков
    final itemsWithChildren = childrenCount.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (itemsWithChildren.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"Горячие зоны"',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Нет предметов с вложенными вещами',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    // Сортируем по количеству потомков
    final sorted = itemsWithChildren.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Берем топ-5
    final topZones = sorted.take(5).toList();

    // Максимум для шкалы
    final maxCount = topZones.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '"Горячие зоны"',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Предметы, в которых хранится больше всего вещей',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Список
        ...topZones.map((entry) {
          final item = entry.key;
          final count = entry.value;
          final percent = (count / maxCount * 100).clamp(10, 100);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$count шт.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    // Фон
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Заполнение
                    Container(
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.7 * (percent / 100),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.brown.shade300,
                            Colors.brown,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 8),

        if (sorted.length > 5)
          Text(
            'И ещё ${sorted.length - 5} мест...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCategories() {
    //id категорий, в которых есть вещи
    final Set<int> categoriesWithItems = {};

    for (var item in _items) {
      if (item.category != null) {
        categoriesWithItems.add(item.category!);
      }
    }

    // категории без вещей
    final emptyCategories = _categories.where(
            (cat) => !categoriesWithItems.contains(cat.id)
    ).toList();

    if (emptyCategories.isEmpty) {
      return const SizedBox.shrink(); // ничего не показываем
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Пустые категории',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'В этих категориях пока нет вещей:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          // список пустых категорий
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emptyCategories.map((category) {
              return Chip(
                label: Text(category.name),
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(color: Colors.grey),
                avatar: const Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          Text(
            'Всего: ${emptyCategories.length} категорий',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}