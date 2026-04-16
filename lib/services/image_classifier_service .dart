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
        'инструменты': [
          'Metal', 'Hammer', 'Screwdriver', 'Wrench', 'Drill', 'Saw', 'Pliers', 'Tape',
          'Ruler', 'Ladder', 'Nail', 'Screw', 'Bolt', 'Paint', 'Brush', 'Roller',
          'Level', 'Clamp', 'Vise', 'Anvil', 'File', 'Chisel', 'Plane'
        ],

        'одежда': [
          'Beard', 'Dress', 'Tights', 'Sunglasses', 'Shorts', 'Necklace',
          'Bracelet', 'Tie', 'Clown', 'Sari', 'Tuxedo', 'Cap', 'Hat',
          'Beanie', 'Jersey', 'Scarf', 'Jacket', 'Leggings', 'Blazer',
          'Polo', 'Jeans', 'Gown', 'Bangs', 'Veil', 'Bride', 'Gloves',
          'Uniform', 'Sweater', 'Coat', 'Suit', 'Scarf', 'Pajamas'
        ],

        'обувь': [
          'Shoe', 'Sneakers', 'Boot', 'Sandals', 'Slippers', 'Flip-flops',
          'High heels', 'Loafers', 'Espadrilles', 'Moccasins', 'Clogs'
        ],

        'мебель': [
          'Chair', 'Desk', 'Couch', 'Bed', 'Wardrobe', 'Cabinet', 'Shelf',
          'Bookcase', 'Table', 'Stool', 'Bench', 'Dresser', 'Cupboard',
          'Rack', 'Loveseat', 'Countertop', 'Drawer', 'Armrest', 'Bunk bed',
          'Cabinetry', 'Cushion', 'Pillow', 'Tablecloth', 'Doily'
        ],

        'электроника': [
          'Computer', 'Mobile phone', 'Television', 'Helicopter', 'Rocket',
          'Subwoofer', 'Aircraft', 'Car', 'Airliner', 'Van', 'Bicycle',
          'Motorcycle', 'Train', 'Submarine', 'Speedboat', 'Scooter',
          'Laptop', 'Tablet', 'Keyboard', 'Mouse', 'Monitor', 'Camera',
          'Headphones', 'Speaker', 'Charger', 'Battery', 'Remote', 'Drone',
          'Printer', 'Scanner', 'Router', 'Smartwatch', 'VR headset'
        ],

        'посуда': [
          'Cup', 'Plate', 'Glass', 'Bowl', 'Mug', 'Fork', 'Knife', 'Spoon',
          'Pan', 'Pot', 'Kettle', 'Teapot', 'Cutlery', 'Cookware and bakeware',
          'Porcelain', 'Saucer', 'Cake', 'Pie', 'Cupcake', 'Muffin',
          'Bag', 'Handbag', 'Backpack', 'Luggage', 'Diaper bag', 'Pet carrier',
          'Baby carrier', 'Wallet'
        ],

        'книги': [
          'Book', 'Comics', 'Newspaper', 'Magazine', 'Notebook', 'Diary',
          'Journal', 'Textbook', 'Novel', 'Encyclopedia', 'Album', 'Catalog', 'Poster',
        ],

        'хобби': [
          'Game', 'Toy', 'Puzzle', 'Chess', 'Music', 'Guitar', 'Piano', 'Violin',
          'Painting', 'Brush', 'Canvas', 'Yarn', 'Knitting', 'Crochet', 'Sewing',
          'Quilting', 'Needlework', 'Embroidery', 'Photography', 'Camera', 'Drone',
          'Skateboard', 'Skateboarder', 'Longboard', 'Surfboard', 'Surfing',
          'Snowboarding', 'Skiing', 'Waterskiing', 'Wakeboarding', 'Scuba diving',
          'Snorkeling', 'Rafting', 'Kayak', 'Canoe', 'Rowing', 'Sailing',
          'Fishing', 'Hiking', 'Camping', 'Backpacking', 'Climbing', 'Caving',
          'Archery', 'Curling', 'Gymnastics', 'Yoga', 'Dance', 'Ballet',
          'Concert', 'Festival', 'Circus', 'Carnival', 'Fireworks', 'Sparkler',
          'Model', 'Miniature', 'Lego', 'Puzzle', 'Board game', 'Video game'
        ],

        'медицина': [
          'Medical', 'Medicine', 'Health', 'First aid', 'Bandage', 'Pill', 'Tablet',
          'Syringe', 'Thermometer', 'Mask', 'Gloves', 'Stethoscope', 'Wheelchair',
          'Crutch', 'Plaster', 'Gauze', 'Cotton', 'Antiseptic', 'Vitamins'
        ],

        'канцелярия': [
          'Pen', 'Pencil', 'Paper', 'Notebook', 'Folder', 'File', 'Clip',
          'Stapler', 'Scissors', 'Glue', 'Tape', 'Envelope', 'Marker',
          'Highlighter', 'Ruler', 'Eraser', 'Calculator', 'Calendar',
          'Notepad', 'Clipboard', 'Whiteboard', 'Blackboard', 'Chalk',
          'Sharpener', 'Binder', 'Sticky notes', 'Index card', 'Post-it'
        ],

        'животные': [
          'Dog', 'Cat', 'Bird', 'Horse', 'Lion', 'Hamster', 'Rabbit', 'Hare',
          'Angora', 'Shetland sheepdog', 'Dalmatian', 'Basset hound', 'Cairn terrier',
          'Shikoku', 'Pixie-bob', 'Sphynx', 'Penguin', 'Turtle', 'Crocodile',
          'Duck', 'Seal', 'Butterfly', 'Insect', 'Dragonfly', 'Bee', 'Ladybug',
          'Fish', 'Goldfish', 'Koi', 'Tropical fish', 'Parrot', 'Pigeon', 'Sparrow'
        ],

        'светильники': [
          'Lamp', 'Light', 'Lantern', 'Chandelier', 'Floor lamp', 'Table lamp',
          'Desk lamp', 'Night light', 'Ceiling light', 'Wall light', 'String lights',
          'Neon', 'Flashlight', 'Headlamp', 'Candle', 'Candlestick', 'Candelabra'
        ],

        'декор': [
          'Vase', 'Mirror', 'Clock', 'Picture frame', 'Artwork',
          'Sculpture', 'Statue', 'Figurine', 'Collectible', 'Jewelry box',
          'Music box', 'Ornament', 'Wreath', 'Garland', 'Tree topper',
          'Candlestick', 'Menorah', 'Kinara', 'Flowerpot', 'Plant', 'Flower'
        ],

        'хранение': [
          'Basket', 'Box', 'Chest', 'Trunk', 'Storage bin', 'Toolbox',
          'Jewelry box', 'Music box', 'Diaper bag'
        ],

        'сумки': [
          'Bag', 'Handbag', 'Backpack', 'Luggage', 'Diaper bag', 'Pet carrier',
          'Baby carrier', 'Wallet'
        ],

        'уборка': [
          'Vacuum cleaner', 'Broom', 'Mop', 'Bucket', 'Sponge', 'Soap',
          'Shampoo', 'Toothbrush', 'Toothpaste', 'Towel', 'Bath mat',
          'Shower curtain', 'Iron', 'Ironing board'
        ],

        'текстиль': [
          'Towel', 'Bathrobe', 'Rug', 'Carpet', 'Curtain', 'Baby blanket'
        ],

        'хоз. инструменты': [
          'Toolbox', 'Ladder', 'Step stool', 'Extension cord', 'Power strip',
          'Batteries', 'Charger', 'Adapter', 'Cable', 'Wire', 'Duct tape',
          'Super glue', 'Measuring tape', 'Level', 'Stud finder', 'Utility knife',
          'Safety glasses', 'Work gloves', 'Apron', 'Gardening gloves', 'Shovel',
          'Rake', 'Hoe', 'Pruning shears', 'Watering can', 'Hose', 'Sprinkler',
          'Lawn mower', 'Snow shovel', 'Ice scraper'
        ],

        'техника': [
          'Radio', 'Alarm clock', 'Fan', 'Heater', 'Air conditioner',
          'Humidifier', 'Dehumidifier', 'Air purifier', 'Thermostat',
          'Smoke detector', 'Carbon monoxide detector', 'Fire extinguisher',
          'Baby monitor', 'Sewing machine', 'Vacuum cleaner', 'Iron'
        ],

        'безопасность': [
          'First aid kit', 'Smoke detector', 'Carbon monoxide detector',
          'Fire extinguisher', 'Safety glasses', 'Work gloves'
        ],

        'детское': [
          'Baby bottle', 'Baby pacifier', 'Baby toy', 'Baby blanket',
          'Baby clothes', 'Diaper', 'Diaper bag', 'Stroller', 'Baby carrier',
          'High chair', 'Playpen', 'Crib', 'Baby monitor', "Children's book",
          'Educational toy', 'Building blocks',
          'Toy', 'Stuffed toy', 'Plush', 'Balloon', 'Baby toy', 'Educational toy',
          'Building blocks', 'Board game', 'Card game', 'Puzzle', 'Pet toy'
        ],

        'творчество': [
          'Craft supplies', 'Drawing supplies', 'Coloring book', 'Crayons',
          'Markers', 'Paint', 'Brushes', 'Easel', 'Sewing machine', 'Sewing kit',
          'Fabric', 'Thread', 'Needle', 'Pin cushion', 'Knitting needles',
          'Crochet hook', 'Yarn', 'Embroidery hoop', 'Cross stitch', 'Scrapbook',
          'Stickers', 'Washi tape', 'Rubber stamps', 'Ink pad'
        ],

        'праздники': [
          'Gift wrap', 'Ribbon', 'Gift bag', 'Gift tag', 'Greeting card',
          'Christmas decoration', 'Ornament', 'Wreath', 'Garland', 'Tree topper',
          'Candlestick', 'Menorah', 'Kinara', 'Advent calendar', 'Easter basket',
          'Halloween decoration', 'Costume', 'Party decoration', 'Banner', 'Confetti'
        ],

        'аксессуары': [
          'Watch', 'Wallet', 'Keys', 'Keychain', 'Sunglasses', 'Jewelry box'
        ],

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

      final Map<Category, double> categoryScores = {};

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final score = label.confidence;

        _searchIndex.forEach((word, category) {
          final wordLower = word.toLowerCase();

          // точное совпадение (полный вес)
          if (text == wordLower) {
            categoryScores[category] = (categoryScores[category] ?? 0) + score;
          }
          // частичное совпадение (половина веса)
          else if (text.contains(wordLower)) {
            categoryScores[category] = (categoryScores[category] ?? 0) + score * 0.5;
          }
        });
      }

      if (categoryScores.isEmpty) return null;

      // категория с максимальным суммарным весом
      Category? bestCategory;
      double bestScore = 0;

      categoryScores.forEach((category, totalScore) {
        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestCategory = category;
        }
      });

      print('===== Распознанные метки:');
      for (final label in labels) {
        print('  ${label.label}: ${label.confidence}');
      }
      print('===== Результаты голосования:');
      categoryScores.forEach((category, score) {
        print('  ${category.name}: ${score.toStringAsFixed(2)}');
      });
      print('===== Выбрано: ${bestCategory?.name} (вес: ${bestScore.toStringAsFixed(2)})');
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