import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app_mobile/pages/item_list_page.dart';

void main() {
  testWidgets('Тест: Кнопка добавления новой вещи отображается', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ItemListPage(),
      ),
    );
    await tester.pump();

    // проверка кнопок
    expect(find.text('Мои вещи'), findsOneWidget); //AppBar
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    print('Кнопка добавления новой вещи отображается');
  });

  testWidgets('Тест: Элементы интерфейса для редактирования', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ItemListPage(),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);

    expect(find.byIcon(Icons.search), findsOneWidget);

    print('Элементы интерфейса для редактирования отображаются');
  });
}