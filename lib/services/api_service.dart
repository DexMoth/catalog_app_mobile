import 'dart:convert';

import 'package:catalog_app_mobile/models/reminder.dart';
import 'package:catalog_app_mobile/models/tag.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';
import 'package:catalog_app_mobile/configuration/app_config.dart';

class ApiService {
  // временный userId для тестирования
  static const int _currentUserId = 2;

  // вспомогательный метод для добавления userId к URL
  String _urlWithUserId(String path) {
    return '$baseUrl$path?userId=$_currentUserId';
  }

  Future<List<Item>> getItems({String searchQuery = ''}) async {

    var url = _urlWithUserId('/item');

    if (searchQuery.isNotEmpty) {
      final query = Uri.encodeQueryComponent(searchQuery);
      url += '?search=$query';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Item> createItem(Item item) async {
    var url = _urlWithUserId('/item');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': item.name,
        'description': item.description,
        'imagePath': item.imagePath,
        'parentId': item.parentId,
        'category': item.category,
        'tags': item.tags,
        'userId': _currentUserId,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return Item.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create item');
    }
  }

  Future<Item> updateItem(Item item) async {
    var url = _urlWithUserId('/item/${item.id}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': item.name,
          'description': item.description,
          'imagePath': item.imagePath,
          'parentId': item.parentId,
          'category': item.category,
          'tags': item.tags,
          'createdAt': item.createdAt.toIso8601String(),
          'updatedAt': item.updatedAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Item.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка обновления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // обновление только тегов
  Future<void> updateItemTags(int itemId, List<int> tags) async {
    var url = _urlWithUserId('/item/$itemId/tags');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'tags': tags}),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления тегов: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // обновление только категорий
  Future<void> updateItemCategories(int itemId, List<int> categories) async {
    var url = _urlWithUserId('/item/$itemId/categories');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'categories': categories}),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления категорий: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<List<Item>> getChildrenItems(int parentId) async {
    final url = _urlWithUserId('/item/$parentId/children');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
    throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<List<Item>> getItemsWithoutParent() async {
    var url = _urlWithUserId('/item/roots');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<bool> deleteItem(int itemId) async {
   var url = _urlWithUserId('/item/$itemId');

    try {
      final response = await http.delete(
        Uri.parse(url),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }


  ///////////////// ТЕГИ //////////////
  Future<List<Tag>> getTags() async {
    final url = _urlWithUserId('/tag');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Tag.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Tag> createTag(String name) async {
    final url = _urlWithUserId('/tag');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({''
          'name': name,
          'userId': _currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      return Tag.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<Tag> updateTag(Tag tag) async {
    final url = _urlWithUserId('/tag/${tag.id}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': tag.name,
          'userId': _currentUserId
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Tag.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка обновления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<bool> deleteTag(int tagId) async {
    final url = _urlWithUserId('/tag/$tagId');

    try {
      final response = await http.delete(
        Uri.parse(url),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  ///////////////// КАТЕГОРИИ //////////////
  Future<List<Category>> getCategories() async {
    final url = _urlWithUserId('/category');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Category> getCategory(int id) async {
    final url = _urlWithUserId('/category/$id');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return Category.fromJson(jsonData);
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Category> createCategory(String name) async {
    final url = _urlWithUserId('/category');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({''
          'name': name,
          'userId': _currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<Category> updateCategory(Category category) async {
    final url = _urlWithUserId('/category/${category.id}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': category.name,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Category.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка обновления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    final url = _urlWithUserId('/category/$categoryId');

    try {
      final response = await http.delete(
        Uri.parse(url),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

// reminders

  Future<List<Reminder>> getReminders() async {
    final url = _urlWithUserId('/reminder');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders: ${response.statusCode}');
    }
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final url = _urlWithUserId('/reminder');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({''
        'id': reminder.id,
        'title': reminder.title,
        'description': reminder.description,
        'message': reminder.message,
        'itemId': reminder.itemId,
        'recurrenceRule': reminder.recurrenceRule,
        'reminderDate': reminder.reminderDate?.toIso8601String(),
        'isActive': reminder.isActive,
        'createdAt': reminder.createdAt.toIso8601String(),
        'updatedAt': reminder.updatedAt.toIso8601String(),
        'userId': _currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create reminder');
    }
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final url = _urlWithUserId('/reminder/${reminder.id}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': reminder.id,
          'title': reminder.title,
          'description': reminder.description,
          'message': reminder.message,
          'itemId': reminder.itemId,
          'recurrenceRule': reminder.recurrenceRule,
          'reminderDate': reminder.reminderDate?.toIso8601String(),
          'isActive': reminder.isActive,
          'createdAt': reminder.createdAt.toIso8601String(),
          'updatedAt': reminder.updatedAt.toIso8601String(),
          'userId': _currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Reminder.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка обновления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<void> updateReminderActive(int reminderId, bool isActive) async {
    try {
      final url = '$baseUrl/reminder/$reminderId/active?isActive=$isActive';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update active status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteReminder(int reminderId) async {
    final url = _urlWithUserId('/reminder/$reminderId');

    try {
      final response = await http.delete(
        Uri.parse(url),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }
}