import 'dart:convert';

import 'package:catalog_app_mobile/models/reminder.dart';
import 'package:catalog_app_mobile/models/tag.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';
import 'package:catalog_app_mobile/configuration/app_config.dart';

import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<int?> _getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  // Вспомогательный метод для добавления userId к URL
  Future<String> _urlWithUserId(String path) async {
    final base = await AppConfig.baseUrl;
    final userId = await _getCurrentUserId();
    return '$base$path?userId=$userId';
  }

  // Токен авторизации
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== ITEMS ====================

  Future<List<Item>> getItems({String searchQuery = ''}) async {
    var url = await _urlWithUserId('/item');

    if (searchQuery.isNotEmpty) {
      url += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Item> createItem(Item item) async {
    final url = await _urlWithUserId('/item');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'name': item.name,
        'description': item.description,
        'imagePath': item.imagePath,
        'parentId': item.parentId,
        'category': item.category,
        'tags': item.tags?.map((t) => t.toJson()).toList(),
        'userId': userId,  // ← Теперь это int, а не Future
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
    final url = await _urlWithUserId('/item/${item.id}');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'name': item.name,
          'description': item.description,
          'imagePath': item.imagePath,
          'parentId': item.parentId,
          'category': item.category,
          'tags': item.tags?.map((t) => t.toJson()).toList(),
          'userId': userId,  // ← Теперь int
          'createdAt': item.createdAt.toIso8601String(),
          'updatedAt': item.updatedAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Item.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Элемент не найден');
      } else {
        throw Exception('Ошибка обновления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<List<Item>> getChildrenItems(int parentId) async {
    final url = await _urlWithUserId('/item/$parentId/children');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<List<Item>> getItemsWithoutParent() async {
    final url = await _urlWithUserId('/item/roots');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<bool> deleteItem(int itemId) async {
    final url = await _urlWithUserId('/item/$itemId');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

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

  // ==================== ТЕГИ ====================

  Future<List<Tag>> getTags() async {
    final url = await _urlWithUserId('/tag');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Tag.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tags: ${response.statusCode}');
    }
  }

  Future<Tag> createTag(String name) async {
    final url = await _urlWithUserId('/tag');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'name': name,
        'userId': userId,  // ← Теперь int
      }),
    );

    if (response.statusCode == 200) {
      return Tag.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<Tag> updateTag(Tag tag) async {
    final url = await _urlWithUserId('/tag/${tag.id}');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'name': tag.name,
          'userId': userId,  // ← Теперь int
        }),
      );

      if (response.statusCode == 200) {
        return Tag.fromJson(json.decode(response.body));
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
    final url = await _urlWithUserId('/tag/$tagId');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

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

  // ==================== КАТЕГОРИИ ====================

  Future<List<Category>> getCategories() async {
    final url = await _urlWithUserId('/category');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  Future<Category> getCategory(int id) async {
    final url = await _urlWithUserId('/category/$id');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load category: ${response.statusCode}');
    }
  }

  Future<Category> createCategory(String name) async {
    final url = await _urlWithUserId('/category');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'name': name,
        'userId': userId,  // ← Теперь int
      }),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create category');
    }
  }

  Future<Category> updateCategory(Category category) async {
    final url = await _urlWithUserId('/category/${category.id}');
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'name': category.name,
        }),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
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
    final url = await _urlWithUserId('/category/$categoryId');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

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

  // ==================== НАПОМИНАНИЯ ====================

  Future<List<Reminder>> getReminders() async {
    final url = await _urlWithUserId('/reminder');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders: ${response.statusCode}');
    }
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final url = await _urlWithUserId('/reminder');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'id': reminder.id,
        'title': reminder.title,
        'description': reminder.description,
        'message': reminder.message,
        'itemId': reminder.itemId,
        'recurrenceRule': reminder.recurrenceRule?.toJson(),
        'reminderDate': reminder.reminderDate?.toIso8601String(),
        'isActive': reminder.isActive,
        'createdAt': reminder.createdAt.toIso8601String(),
        'updatedAt': reminder.updatedAt.toIso8601String(),
        'userId': userId,  // ← Теперь int
      }),
    );

    if (response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create reminder');
    }
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final url = await _urlWithUserId('/reminder/${reminder.id}');
    final headers = await _getHeaders();
    final userId = await _getCurrentUserId();  // ← Ждём значение

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'id': reminder.id,
          'title': reminder.title,
          'description': reminder.description,
          'message': reminder.message,
          'itemId': reminder.itemId,
          'recurrenceRule': reminder.recurrenceRule?.toJson(),
          'reminderDate': reminder.reminderDate?.toIso8601String(),
          'isActive': reminder.isActive,
          'createdAt': reminder.createdAt.toIso8601String(),
          'updatedAt': reminder.updatedAt.toIso8601String(),
          'userId': userId,  // ← Теперь int
        }),
      );

      if (response.statusCode == 200) {
        return Reminder.fromJson(json.decode(response.body));
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
      final base = await AppConfig.baseUrl;
      final url = '$base/reminder/$reminderId/active?isActive=$isActive';
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update active status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteReminder(int reminderId) async {
    final url = await _urlWithUserId('/reminder/$reminderId');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

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