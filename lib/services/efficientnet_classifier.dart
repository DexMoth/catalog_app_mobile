import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EfficientNetClassifier {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isReady = false;

  EfficientNetClassifier() {
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      // Загружаем метки
      final labelsRaw = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsRaw.split('\n').where((l) => l.isNotEmpty).toList();
      print('Загружено ${_labels.length} меток');

      // Загружаем модель
      _interpreter = await Interpreter.fromAsset('assets/models/efficientnet-tflite-lite0-int8-v2.tflite');
      _isReady = true;
      print('EfficientNet-Lite0 загружена');
    } catch (e) {
      print('Ошибка загрузки: $e');
    }
  }

  Future<List<Map<String, dynamic>>> classifyImage(File imageFile) async {
    if (!_isReady) return [];

    try {
      final inputFlat = _preprocessImage(imageFile);
      final input = inputFlat.reshape([1, 224, 224, 3]);

      // Создаём выходной массив с указанием типа int
      var output = List.generate(1, (_) => List.filled(1000, 0)).reshape([1, 1000]);
      _interpreter.run(input, output);

      // Приводим к List<double> более надёжным способом
      final logits = <double>[];
      for (var value in output[0]) {
        logits.add((value as int).toDouble());
      }

      return _getTopResults(logits, 3);
    } catch (e) {
      print('Ошибка классификации: $e');
      return [];
    }
  }


  Uint8List  _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Не удалось декодировать изображение');

    img.Image resized = img.copyResize(image, width: 224, height: 224);

    // Uint8List для целых значений 0-255
    var input = Uint8List(1 * 224 * 224 * 3);
    int index = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);

        // INT8 модель: значения 0-255
        input[index++] = pixel.r.toInt();
        input[index++] = pixel.g.toInt();
        input[index++] = pixel.b.toInt();
      }
    }

    return input;
  }

  List<Map<String, dynamic>> _getTopResults(List<double> output, int k) {
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < output.length; i++) {
      results.add({'index': i, 'confidence': output[i]});
    }
    results.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    return results.take(k).where((item) => item['index'] < _labels.length).map((item) {
      // Применяем softmax для преобразования логитов в вероятности
      final confidence = _softmax(output)[item['index']] * 100;
      return {
        'label': _labels[item['index']],
        'confidence': confidence.toStringAsFixed(2),
      };
    }).toList();
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);

    final exponents = logits.map((x) => exp(x - maxLogit)).toList();
    final sum = exponents.reduce((a, b) => a + b);

    return exponents.map((e) => e / sum).toList();
  }

  bool get isReady => _isReady;

  void dispose() {
    _interpreter.close();
  }
}