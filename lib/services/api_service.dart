import 'dart:convert';
import 'dart:ffi';
import 'package:catalog_app_mobile/models/category.dart';
import 'package:catalog_app_mobile/models/tag.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'http://192.168.0.13:8080/api';

  Future<List<Item>> getItems({String searchQuery = ''}) async {

    const url = '$_baseUrl/item';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Item> createItem(Item item) async {
    const url = '$_baseUrl/item';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': item.name,
        'description': item.description,
        'imagePath': item.imagePath,
        'parentId': item.parentId,
        'categories': item.categories,
        'tags': item.tags,
      }),
    );

    if (response.statusCode == 200) {
      return Item.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create item');
    }
  }

  Future<Item> updateItem(Item item) async {
    const url = '$_baseUrl/item';

    try {
      final response = await http.put(
        Uri.parse('$url/${item.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': item.name,
          'description': item.description,
          'imagePath': item.imagePath,
          'parentId': item.parentId,
          'categories': item.categories,
          'tags': item.tags,
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
    const url = '$_baseUrl/item';

    try {
      final response = await http.patch(
        Uri.parse('$url/${itemId}/tags'),
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
    const url = '$_baseUrl/item';

    try {
      final response = await http.patch(
        Uri.parse('$url/${itemId}/categories'),
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
    final url = '$_baseUrl/item/$parentId/children';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
    throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<bool> deleteItem(int itemId) async {
    const url = '$_baseUrl/item';

    try {
      final response = await http.delete(
        Uri.parse('$url/$itemId'),
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
    const url = '$_baseUrl/tag';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Tag.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Tag> createTag(String name) async {
    const url = '$_baseUrl/tag';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      return Tag.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<Tag> updateTag(Tag tag) async {
    const url = '$_baseUrl/tag';

    try {
      final response = await http.put(
        Uri.parse('$url/${tag.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': tag.name,
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
    const url = '$_baseUrl/tag';

    try {
      final response = await http.delete(
        Uri.parse('$url/$tagId'),
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
    const url = '$_baseUrl/category';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Category> createCategory(String name) async {
    const url = '$_baseUrl/category';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<Category> updateCategory(Category category) async {
    const url = '$_baseUrl/category';

    try {
      final response = await http.put(
        Uri.parse('$url/${category.id}'),
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
    const url = '$_baseUrl/category';

    try {
      final response = await http.delete(
        Uri.parse('$url/$categoryId'),
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