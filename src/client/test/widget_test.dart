import 'package:finance_game/main.dart';
import 'package:finance_game/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Прокручивает до виджета и нажимает (кнопки ниже экрана не видны без прокрутки).
Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

Future<void> _login(WidgetTester tester) async {
  await tester.pumpWidget(const FinanceGameApp());
  await tester.enterText(find.byType(TextFormField).at(0), 'student@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await tester.pumpAndSettle();
}

void main() {
  test('formatMoney и parseMoney', () {
    expect(formatMoney(12000), '12 000 ₸');
    expect(formatMoney(0), '0 ₸');
    expect(formatMoney(1234567), '1 234 567 ₸');
    expect(parseMoney(''), 0);
    expect(parseMoney('120 000'), 120000);
    expect(parseMoney('-5'), null);
    expect(parseMoney('abc'), null);
  });

  testWidgets('экран входа показывает поля и кнопку', (tester) async {
    await tester.pumpWidget(const FinanceGameApp());

    expect(find.text('ФинИгра'), findsOneWidget);
    expect(find.text('Почта'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
  });

  testWidgets('некорректная почта и короткий пароль показывают ошибки', (tester) async {
    await tester.pumpWidget(const FinanceGameApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'bad');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();

    expect(find.text('Введите корректную почту'), findsOneWidget);
    expect(find.text('Пароль не короче 6 символов'), findsOneWidget);
  });

  testWidgets('вход ведёт на создание персонажа', (tester) async {
    await _login(tester);

    expect(find.text('Создайте персонажа'), findsOneWidget);
  });

  testWidgets('онбординг: свободный остаток считается на экране финансов', (tester) async {
    await _login(tester);
    await tester.tap(find.byKey(const ValueKey('avatar-next')));
    await tester.pumpAndSettle();

    expect(find.text('Ваши финансы в месяц'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '120000'); // доход
    await tester.enterText(fields.at(1), '40000'); // жильё
    await tester.enterText(fields.at(2), '50000'); // питание
    await tester.enterText(fields.at(3), '10000'); // транспорт
    await tester.enterText(fields.at(4), '3000'); // связь
    await tester.enterText(fields.at(5), '5000'); // прочее
    await tester.pump();

    expect(find.text('12 000 ₸'), findsOneWidget);
  });

  testWidgets('онбординг с пустым доходом не пускает дальше', (tester) async {
    await _login(tester);
    await tester.tap(find.byKey(const ValueKey('avatar-next')));
    await tester.pumpAndSettle();

    await _tapKey(tester, 'finance-start');
    await tester.pump();

    expect(find.text('Укажите доход больше 0'), findsOneWidget);
    expect(find.text('Ваши финансы в месяц'), findsOneWidget);
  });

  testWidgets('полный путь: онбординг → главный экран → сценарий → итог', (tester) async {
    await _login(tester);
    await tester.tap(find.byKey(const ValueKey('avatar-next')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '120000');
    await tester.enterText(fields.at(1), '40000');
    await tester.enterText(fields.at(2), '50000');
    await tester.enterText(fields.at(3), '10000');
    await tester.enterText(fields.at(4), '3000');
    await tester.enterText(fields.at(5), '5000');
    await tester.pump();
    await _tapKey(tester, 'finance-start');
    await tester.pumpAndSettle();

    expect(find.text('Здравствуйте,'), findsOneWidget);
    expect(find.text('12 000 ₸'), findsWidgets);

    // Сценарий: шаг 1 — отложить 10%, шаг 2 — ремонт телефона.
    await _tapKey(tester, 'continue-game');
    await tester.pumpAndSettle();
    expect(find.textContaining('После обязательных расходов'), findsOneWidget);

    await _tapKey(tester, 'option-0-1');
    await tester.pump();
    expect(find.text('Хорошее решение'), findsOneWidget);

    await _tapKey(tester, 'scenario-next');
    await tester.pumpAndSettle();
    expect(find.textContaining('Сломался телефон'), findsOneWidget);

    await _tapKey(tester, 'option-1-0');
    await tester.pump();
    await _tapKey(tester, 'scenario-next');
    await tester.pumpAndSettle();

    expect(find.text('Итог: Конец месяца'), findsOneWidget);
    expect(find.text('Вернуться домой'), findsOneWidget);

    await _tapKey(tester, 'scenario-finish');
    await tester.pumpAndSettle();
    // Главный экран снова открыт, а результат сценария применён: модуль «Личный бюджет» пройден.
    expect(find.byKey(const ValueKey('continue-game')), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
  });
}
