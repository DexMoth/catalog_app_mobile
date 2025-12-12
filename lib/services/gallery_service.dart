// import 'package:gallery_picker/gallery_picker.dart';
// import 'package:flutter/material.dart';
//
// class GalleryService {
//   // Получить одно изображение из галереи
//   static Future<MediaFile?> pickSingleImage(BuildContext context) async {
//     // Для выбора одного файла используем singleMedia: true
//     final List<MediaFile>? mediaFiles = await GalleryPicker.pickMedia(
//       context: context,
//       singleMedia: true,
//     );
//
//     // Возвращаем первый файл или null если список пустой
//     if (mediaFiles != null && mediaFiles.isNotEmpty) {
//       return mediaFiles.first;
//     }
//     return null;
//   }
// }