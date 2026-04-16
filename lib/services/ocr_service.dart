import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

class OcrService {
  Future<String> recognizeText(String imagePath) async {
    try {
      final rusText = await TesseractOcr.extractText(
        imagePath,
        config: OCRConfig(
            language: 'rus',
            engine: OCREngine.tesseract,
        ),
      );

      // если есть кириллица, переключаемся на русский
      //if (_containsCyrillic(rusText)) {
      //  final engText = await TesseractOcr.extractText(
      //    imagePath,
      //    config: OCRConfig(language: 'eng', engine: OCREngine.tesseract),
      //   );
      //  return engText.isNotEmpty ? engText : rusText;
      //}
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

    return cleaned;
  }

  bool _containsCyrillic(String text) {
    final cyrillicPattern = RegExp(r'[\u0400-\u04FF]');
    return cyrillicPattern.hasMatch(text);
  }
}