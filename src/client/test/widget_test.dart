import 'package:finance_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('корректный вход ведёт на главный экран', (tester) async {
    await tester.pumpWidget(const FinanceGameApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'student@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Здравствуйте,'), findsOneWidget);
    expect(find.text('Модули'), findsWidgets);
    expect(find.text('Личный бюджет'), findsOneWidget);
  });
}
