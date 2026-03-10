import 'tag.dart';
import 'category.dart';

class Item {
  final int id;
  String name;
  String? description;
  String? imagePath;
  int? parentId;
  List<Category>? categories;
  List<Tag>? tags;

  Item({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.parentId,
    this.categories,
    this.tags,
  });

  factory Item.empty() {
    return Item(
      id: 0,
      name: '',
      description: null,
      imagePath: null,
      parentId: null,
      categories: null,
      tags: null,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    // для категорий
    List<Category>? categories;
    if (json['categories'] != null) {
      categories = (json['categories'] as List)
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();
    }

    // для тегов
    List<Tag>? tags;
    if (json['tags'] != null) {
      tags = (json['tags'] as List)
          .map((tagJson) => Tag.fromJson(tagJson))
          .toList();
    }

    return Item(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      parentId: json['parentId'] as int?,
      categories: categories,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'parentId': parentId,
      'categories': categories?.map((category) => category.toJson()).toList(),
      'tags': tags?.map((tag) => tag.toJson()).toList(),
    };
  }
}