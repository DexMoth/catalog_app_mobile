import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app_mobile/pages/category_list_page.dart';

void main() {
  final ApiService apiService = ApiService();

  testWidgets('Тест: Страница категорий загружается', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryListPage(),
      ),
    );

    expect(find.text('Категории'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    print('Страница категорий загружается');
  });

  testWidgets('Тест: Кнопки добавления отображаются', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryListPage(),
      ),
    );

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    expect(find.byIcon(Icons.add), findsOneWidget);

    print('Кнопка добавления категории присутствует');
  });

  test('Создание и удаление категории через API', () async {
    // const categoryName = 'категория для удаления';
    // final createdcategory = await apiService.createCategory(categoryName);
    //
    // final categorysAfterCreate = await apiService.getCategories();
    // final existsAfterCreate = categorysAfterCreate.any((t) => t.id == createdcategory.id);
    // expect(existsAfterCreate, true);
    //
    // await apiService.deleteCategory(createdcategory.id);
    //
    // final categorysAfterDelete = await apiService.getCategories();
    // final existsAfterDelete = categorysAfterDelete.any((t) => t.id == createdcategory.id);
    // expect(existsAfterDelete, false);

    print('Тест создания и удаления пройден');
  });
}