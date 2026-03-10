// image_classifier_service.dart
import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class ImageClassifierService {
  late final ImageLabeler _labeler;
  Map<String, Category> _searchIndex = {}; // слово → категория

  ImageClassifierService() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.3);
    _labeler = ImageLabeler(options: options);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getCategories();

      final synonyms = {
        'одежда': ['clothing', 'shirt', 't-shirt', 'jacket', 'jeans', 'dress',
          'skirt', 'pants', 'sweater', 'coat', 'suit',
          'shoe', 'boot', 'sneaker', 'sandal', 'hat', 'cap',
          'glove', 'scarf', 'uniform', 'swimwear'],

        'мебель': ['furniture', 'table', 'chair', 'sofa', 'couch', 'bed',
          'wardrobe', 'cabinet', 'shelf', 'bookcase', 'desk',
          'stool', 'bench', 'dresser', 'cupboard', 'rack'],

        'электроника': ['electronics', 'laptop', 'computer', 'phone', 'smartphone',
          'tablet', 'keyboard', 'mouse', 'monitor', 'tv',
          'television', 'camera', 'headphones', 'speaker',
          'charger', 'battery', 'remote'],

        'посуда': ['dishes', 'plate', 'cup', 'glass', 'bowl', 'mug',
          'utensils', 'fork', 'knife', 'spoon', 'pan', 'pot',
          'kettle', 'teapot'],

        'книги': ['book', 'books', 'textbook', 'novel', 'magazine',
          'notebook', 'diary', 'journal', 'comic'],

        'хобби': ['hobby', 'hobbies', 'game', 'toy', 'puzzle', 'chess',
          'music', 'guitar', 'piano', 'violin', 'painting',
          'brush', 'canvas', 'yarn', 'knitting', 'fishing',
          'sport', 'ball', 'dance', 'photography', 'camera'],

        'инструменты': ['tools', 'tool', 'hammer', 'screwdriver', 'wrench',
          'drill', 'saw', 'pliers', 'tape', 'ruler',
          'ladder', 'nail', 'screw', 'bolt', 'painting',
          'brush', 'roller'],

        'медицина': ['medical', 'medicine', 'health', 'first aid', 'bandage',
          'pill', 'tablet', 'syringe', 'thermometer', 'mask',
          'gloves', 'stethoscope', 'wheelchair', 'crutch'],

        'канцелярия': ['stationery', 'office', 'pen', 'pencil', 'paper', 'notebook',
          'folder', 'file', 'clip', 'stapler', 'scissors', 'glue',
          'tape', 'envelope', 'marker', 'highlighter', 'ruler',
          'eraser', 'calculator', 'calendar', 'notepad', 'clipboard'],

        'животные' : ['dog', 'cat', 'bird', 'horse', 'lion', 'hamster',
          'wood rabbit', 'hare', 'Angora',],

      };

      for (final category in categories) {
        final name = category.name.toLowerCase();
        _searchIndex[name] = category;

        if (synonyms.containsKey(name)) {
          for (final word in synonyms[name]!) {
            _searchIndex[word] = category;
          }
        }
      }

      print('Загружено категорий: ${categories.length}');
    } catch (e) {
      print('Ошибка категорий: $e');
    }
  }

  Future<Category?> findCategory(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final labels = await _labeler.processImage(inputImage);

      Category? bestCategory;
      double bestScore = 0;

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final score = label.confidence;

        _searchIndex.forEach((word, category) {
          if (text.contains(word)) {
            if (score > bestScore) {
              bestScore = score;
              bestCategory = category;
            }
          }
        });
      }

      return bestCategory;
    } catch (e) {
      print('Ошибка: $e');
      return null;
    }
  }

  void dispose() {
    _labeler.close();
  }
}