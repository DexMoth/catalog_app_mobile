import 'package:catalog_app_mobile/pages/item_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app_mobile/pages/item_edit_page.dart';
import 'package:catalog_app_mobile/models/item.dart';

void main() {
  testWidgets('Тест: Страница создания имеет правильные элементы', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditItemPage(),
      ),
    );

    expect(find.text('Создание'), findsOneWidget);

    expect(find.text('Название вещи'), findsOneWidget);
    expect(find.text('Описание'), findsOneWidget);

    expect(find.byType(TextField), findsNWidgets(2));

    expect(find.text('Галерея'), findsOneWidget);
    expect(find.text('Камера'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);

    expect(find.byIcon(Icons.save), findsOneWidget);
    print('Страница создания имеет правильные элементы');

  });

  testWidgets('Тест: Страница редактирования заполнена данными', (WidgetTester tester) async {
    final item = Item(
      id: 1,
      name: 'Моя книга',
      description: 'Интересная книга',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditItemPage(item: item),
      ),
    );

    expect(find.text('Редактирование'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Моя книга'), findsOneWidget);
    print('Страница редактирования заполнена данными');
  });

  testWidgets('Тест: Ошибка при пустом названии', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditItemPage(),
      ),
    );

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, '');

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Ошибка'), findsOneWidget);
    expect(find.textContaining('Введите название вещи'), findsOneWidget);
    print('Ошибка при пустом названии отображается');
  });

  testWidgets('Тест: Кнопка отмены присутствует', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditItemPage(),
      ),
    );

    expect(find.text('Отмена'), findsOneWidget);

    print('Элементы интерфейса для редактирования отображаются');
  });

  testWidgets('Тест: Секция изображения отображается', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditItemPage(),
      ),
    );

    expect(find.byIcon(Icons.photo), findsOneWidget);

    expect(find.byIcon(Icons.photo_library), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    print('Секция изображения отображается');
  });
}