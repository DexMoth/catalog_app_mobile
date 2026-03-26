import 'tag.dart';
import 'category.dart';

class Item {
  final int id;
  String name;
  String? description;
  String? imagePath;
  int? parentId;
  int? category;
  List<Tag>? tags;
  DateTime createdAt;
  DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.parentId,
    this.category,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.empty() {
    return Item(
      id: 0,
      name: '',
      description: null,
      imagePath: null,
      parentId: null,
      category: null,
      tags: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now()
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
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
      category: json['category'] as int?,
      tags: tags,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'parentId': parentId,
      'category': category,
      'tags': tags?.map((tag) => tag.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}