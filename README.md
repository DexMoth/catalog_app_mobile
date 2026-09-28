# catalog_app_mobile
Мобильное приложение для каталогизации имущества (дипломный проект) – полноценное клиент-серверное приложение для учёта личного имущества с использованием искусственного интеллекта.
Стек: Flutter (Dart), Java 17, Spring Boot, PostgreSQL, JUnit, Apache JMeter

Основные функции:
•	автоматически распознаёт категорию предмета по фото и предлагает название (встроена ML-модель),
•	реализована иерархия вещей и окно перемещения, авторизация пользователей,
•	интеграция с почтой (отправка кода подтверждения),
•	локальные уведомления,
•	сохранение данных в shared preferences,
•	работа с камерой и галереей устройства.


### Посмотреть демо проект для ознакомления: https://drive.google.com/file/d/1zEK3ETFe1bnfLRaDagSOsRPSsye14zhA/view?usp=drive_link

## Подключение к телефону (физический носитель)

Нужно запустить команду
```adb reverse tcp:8080 tcp:8080```

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

