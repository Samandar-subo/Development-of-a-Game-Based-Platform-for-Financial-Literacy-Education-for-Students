import 'package:flutter/material.dart';

import '../theme.dart';

/// Главный экран: баланс, накопления, долг, личный план и модули.
/// Соответствует главному экрану прототипа. Значения — демонстрационные.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.name});

  final String name;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // Демонстрационные значения, как в прототипе (доход 120 000 ₸, расходы 108 000 ₸).
  static const _income = 120000;
  static const _expenses = 108000;
  static const _balance = 12000;
  static const _savings = 0;
  static const _debt = 0;

  static const _modules = [
    _Module('Личный бюджет', 'Остаток, резерв и непредвиденные траты', '💰', 0.0),
    _Module('Кредиты и рассрочка', 'Полная стоимость и переплата', '💳', 0.0),
    _Module('Мошенничество', 'Как распознать опасную ситуацию', '🛡️', 0.0),
    _Module('Накопления и инфляция', 'Реальная доходность и риски', '📈', 0.0),
  ];

  String _money(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf ₸';
  }

  @override
  Widget build(BuildContext context) {
    const free = _income - _expenses;
    const reserveTarget = _expenses * 3;
    final reserveShare = reserveTarget == 0 ? 0.0 : (_savings / reserveTarget).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Greeting(name: widget.name),
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(label: 'Баланс', value: _money(_balance)),
                const SizedBox(width: 8),
                _Stat(label: 'Накопления', value: _money(_savings)),
                const SizedBox(width: 8),
                _Stat(label: 'Долг', value: _money(_debt)),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PlanRow('Доход в месяц', _money(_income)),
                    _PlanRow('Обязательные расходы', _money(_expenses)),
                    _PlanRow('Свободно', _money(free)),
                    _PlanRow('Резерв (цель — 3 месяца расходов)', _money(reserveTarget)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: reserveShare),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Накоплено ${(reserveShare * 100).round()}% от цели',
                        style: const TextStyle(color: AppColors.mutedLight, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Продолжить игру'),
            ),
            const SizedBox(height: 16),
            Text('Модули', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            for (final m in _modules) _ModuleCard(module: m),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Text('🏠'), label: 'Главная'),
          NavigationDestination(icon: Text('📚'), label: 'Модули'),
          NavigationDestination(icon: Text('📈'), label: 'Прогресс'),
          NavigationDestination(icon: Text('👤'), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _Module {
  const _Module(this.title, this.desc, this.icon, this.progress);

  final String title;
  final String desc;
  final String icon;
  final double progress;
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Аватар-заглушка: в прототипе это SVG-персонаж, здесь — инициал.
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(fontSize: 24, color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Здравствуйте,', style: TextStyle(color: Colors.white70)),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.mutedLight, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.mutedLight, fontSize: 14))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _Module module;

  @override
  Widget build(BuildContext context) {
    final percent = (module.progress * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(module.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(module.desc, style: const TextStyle(color: AppColors.mutedLight, fontSize: 13)),
                    ],
                  ),
                ),
                Text('$percent%', style: const TextStyle(color: AppColors.mutedLight, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: module.progress),
          ],
        ),
      ),
    );
  }
}
