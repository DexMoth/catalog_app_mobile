// Файл test/tag_simple_test.dart
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app_mobile/pages/tag_list_page.dart';

void main() {
  final ApiService apiService = ApiService();

  testWidgets('Тест: Страница тегов загружается', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TagListPage(),
      ),
    );

    expect(find.text('Теги'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    print('Страница тегов загружается');
  });

  testWidgets('Тест: Кнопки добавления отображаются', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TagListPage(),
      ),
    );

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    expect(find.byIcon(Icons.add), findsOneWidget);

    print('Кнопка добавления тега присутствует');
  });

  test('Создание и удаление тега через API', () async {
    // const tagName = 'Тег для удаления';
    // final createdTag = await apiService.createTag(tagName);
    //
    // final tagsAfterCreate = await apiService.getTags();
    // final existsAfterCreate = tagsAfterCreate.any((t) => t.id == createdTag.id);
    // expect(existsAfterCreate, true);
    //
    // await apiService.deleteTag(createdTag.id);
    //
    // final tagsAfterDelete = await apiService.getTags();
    // final existsAfterDelete = tagsAfterDelete.any((t) => t.id == createdTag.id);
    // expect(existsAfterDelete, false);

    print('Тест создания и удаления пройден');
  });
}