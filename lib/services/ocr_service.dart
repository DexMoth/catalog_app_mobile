import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

class OcrService {
  Future<String> recognizeText(String imagePath) async {
    try {
      var rusText = await TesseractOcr.extractText(
        imagePath,
        config: OCRConfig(
            language: 'rus',
            engine: OCREngine.tesseract,
        ),
      );

      if (rusText == "") {
        rusText = await TesseractOcr.extractText(
          imagePath,
          config: OCRConfig(
            language: 'eng',
            engine: OCREngine.tesseract,
          ),
        );
      }

      var text = _cleanText(rusText);
      return text;
    } catch (e) {
      print('Ошибка OCR: $e');
      return '';
    }
  }

  /// очистка распознанного текста
  String _cleanText(String text) {
    // убираем лишние переносы строк
    String cleaned = text.replaceAll('\n', ' ');
    // убираем множественные пробелы
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();

    // обрезаем до 3 слов
    final words = cleaned.split(' ');
    if (words.length > 3) {
      cleaned = words.take(3).join(' ');
    }

    return cleaned;
  }

  bool _containsCyrillic(String text) {
    final cyrillicPattern = RegExp(r'[\u0400-\u04FF]');
    return cyrillicPattern.hasMatch(text);
  }
}