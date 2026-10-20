import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme.dart';
import '../utils/money.dart';
import 'scenario_screen.dart';

/// Главный экран: баланс, накопления, долг, личный план и модули.
/// Значения берутся из профиля, введённого студентом на онбординге.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late int _balance;
  late int _savings;
  late int _debt;
  int _points = 0;
  bool _budgetDone = false;

  @override
  void initState() {
    super.initState();
    _balance = widget.profile.free;
    _savings = widget.profile.savings;
    _debt = widget.profile.debt;
  }

  Future<void> _openScenario() async {
    final result = await Navigator.of(context).push<ScenarioResult>(
      MaterialPageRoute(
        builder: (_) => ScenarioScreen(
          profile: widget.profile,
          balance: _balance,
          savings: _savings,
          debt: _debt,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _balance = result.balance;
      _savings = result.savings;
      _debt = result.debt;
      _points += result.points;
      _budgetDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final target = p.reserveTarget;
    final reserveShare = target == 0 ? 0.0 : (_savings / target).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: p.avatar.shirt,
                    child: Text(p.avatar.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Здравствуйте,', style: TextStyle(color: Colors.white70)),
                        Text(p.name,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        Text('Очки: $_points', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(label: 'Баланс', value: formatMoney(_balance)),
                const SizedBox(width: 8),
                _Stat(label: 'Накопления', value: formatMoney(_savings)),
                const SizedBox(width: 8),
                _Stat(label: 'Долг', value: formatMoney(_debt)),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PlanRow('Доход в месяц', formatMoney(p.income)),
                    _PlanRow('Обязательные расходы', formatMoney(p.expenses)),
                    _PlanRow('Свободно', formatMoney(p.free)),
                    _PlanRow('Резерв (цель — 3 месяца расходов)', formatMoney(target)),
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
              key: const ValueKey('continue-game'),
              onPressed: _openScenario,
              child: const Text('Продолжить игру'),
            ),
            const SizedBox(height: 16),
            Text('Модули', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            _ModuleCard(
              title: 'Личный бюджет',
              desc: 'Остаток, резерв и непредвиденные траты',
              icon: '💰',
              progress: _budgetDone ? 1 : 0,
              onTap: _openScenario,
            ),
            for (final m in const [
              ('Кредиты и рассрочка', 'Полная стоимость и переплата', '💳'),
              ('Мошенничество', 'Как распознать опасную ситуацию', '🛡️'),
              ('Накопления и инфляция', 'Реальная доходность и риски', '📈'),
            ])
              _ModuleCard(title: m.$1, desc: m.$2, icon: m.$3, progress: 0, onTap: null),
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
              FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
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
  const _ModuleCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String desc;
  final String icon;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(desc, style: const TextStyle(color: AppColors.mutedLight, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('$percent%', style: const TextStyle(color: AppColors.mutedLight, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
    );
  }
}
