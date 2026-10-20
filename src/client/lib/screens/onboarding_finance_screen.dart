import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../utils/money.dart';
import 'home_screen.dart';

/// Шаг 2 онбординга: студент вводит свои доход, расходы, накопления и долги.
/// Свободный остаток считается на экране сразу.
class OnboardingFinanceScreen extends StatefulWidget {
  const OnboardingFinanceScreen({super.key, required this.name, required this.avatarIndex});

  final String name;
  final int avatarIndex;

  @override
  State<OnboardingFinanceScreen> createState() => _OnboardingFinanceScreenState();
}

class _OnboardingFinanceScreenState extends State<OnboardingFinanceScreen> {
  final _income = TextEditingController();
  final _housing = TextEditingController();
  final _food = TextEditingController();
  final _transport = TextEditingController();
  final _phone = TextEditingController();
  final _other = TextEditingController();
  final _savings = TextEditingController();
  final _debt = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_income, _housing, _food, _transport, _phone, _other, _savings, _debt]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Сумма обязательных расходов по введённым полям или null, если есть некорректный ввод.
  int? _expensesTotal() {
    var total = 0;
    for (final c in [_housing, _food, _transport, _phone, _other]) {
      final v = parseMoney(c.text);
      if (v == null) return null;
      total += v;
    }
    return total;
  }

  int _freePreview() {
    final income = parseMoney(_income.text) ?? 0;
    final expenses = _expensesTotal() ?? 0;
    return (income - expenses).clamp(0, income).toInt();
  }

  void _start() {
    final income = parseMoney(_income.text);
    final expenses = _expensesTotal();
    final savings = parseMoney(_savings.text);
    final debt = parseMoney(_debt.text);

    if (income == null || savings == null || debt == null || expenses == null) {
      setState(() => _error = 'Введите неотрицательные числа в каждом поле');
      return;
    }
    if (income <= 0) {
      setState(() => _error = 'Укажите доход больше 0');
      return;
    }

    final profile = UserProfile(
      name: widget.name,
      avatarIndex: widget.avatarIndex,
      income: income,
      expenses: expenses,
      savings: savings,
      debt: debt,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
      (route) => route.isFirst,
    );
  }

  Widget _field(String label, TextEditingController c, {ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, hintText: '0'),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваши финансы в месяц')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Text('Введите свои цифры. Игра пересчитает сценарии под вас.'),
            const SizedBox(height: 16),
            _field('Доход в месяц (стипендия и подработка), ₸', _income, onChanged: (_) => setState(() {})),
            const Text('Обязательные расходы, ₸', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field('Жильё', _housing, onChanged: (_) => setState(() {})),
            _field('Питание', _food, onChanged: (_) => setState(() {})),
            _field('Транспорт', _transport, onChanged: (_) => setState(() {})),
            _field('Связь и интернет', _phone, onChanged: (_) => setState(() {})),
            _field('Прочее', _other, onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(child: Text('Свободно в месяц')),
                    Text(
                      formatMoney(_freePreview()),
                      key: const ValueKey('free-amount'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Что уже есть', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field('Накопления, ₸', _savings),
            _field('Долги, ₸', _debt),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('finance-start'),
              onPressed: _start,
              child: const Text('Начать игру'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
