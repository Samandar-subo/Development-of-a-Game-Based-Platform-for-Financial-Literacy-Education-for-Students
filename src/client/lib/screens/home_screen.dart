import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme.dart';
import '../utils/money.dart';
import 'login_screen.dart';
import 'scenario_screen.dart';

/// Описание модуля обучения.
class _Module {
  const _Module(this.title, this.desc, this.icon, {this.available = false});

  final String title;
  final String desc;
  final String icon;

  /// Есть ли у модуля сценарий в этой версии клиента.
  final bool available;
}

const _modules = <_Module>[
  _Module('Личный бюджет', 'Остаток, резерв и непредвиденные траты', '💰', available: true),
  _Module('Кредиты и рассрочка', 'Полная стоимость и переплата', '💳'),
  _Module('Мошенничество', 'Как распознать опасную ситуацию', '🛡️'),
  _Module('Накопления и инфляция', 'Реальная доходность и риски', '📈'),
];

/// Главный экран с нижней навигацией: «Главная», «Модули», «Прогресс», «Профиль».
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

  /// Пройденные сценарии по порядку; каждый сценарий — один игровой месяц.
  final List<ScenarioResult> _history = [];

  bool get _budgetDone => _history.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    _balance = widget.profile.free;
    _savings = widget.profile.savings;
    _debt = widget.profile.debt;
    _points = 0;
    _history.clear();
  }

  Future<void> _openScenario() async {
    final p = widget.profile;
    // Первый месяц уже учтён в стартовом балансе. Каждый следующий сценарий —
    // новый месяц, и на карту поступает свободный остаток.
    final newMonth = _history.isNotEmpty;
    final startBalance = newMonth ? _balance + p.free : _balance;

    final messenger = ScaffoldMessenger.of(context);
    if (newMonth && p.free > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text('Месяц ${_history.length + 1}: на карту поступило ${formatMoney(p.free)}'),
        duration: const Duration(seconds: 2),
      ));
    }

    final result = await Navigator.of(context).push<ScenarioResult>(
      MaterialPageRoute(
        builder: (_) => ScenarioScreen(
          profile: p,
          balance: startBalance,
          savings: _savings,
          debt: _debt,
        ),
      ),
    );
    messenger.hideCurrentSnackBar();
    // Выход из незавершённого сценария ничего не меняет.
    if (result == null || !mounted) return;
    setState(() {
      _balance = result.balance;
      _savings = result.savings;
      _debt = result.debt;
      _points += result.points;
      _history.add(result);
    });
  }

  void _openModule(_Module m) {
    if (m.available) {
      _openScenario();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Модуль «${m.title}» пока в разработке')));
  }

  double _moduleProgress(_Module m) => m.available && _budgetDone ? 1 : 0;

  Future<bool> _confirm(String title, String text, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _resetProgress() async {
    if (!await _confirm('Сбросить прогресс?', 'Очки, история сценариев и деньги вернутся к начальным значениям.',
        'Сбросить')) {
      return;
    }
    if (!mounted) return;
    setState(_resetState);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Прогресс сброшен')));
  }

  Future<void> _logout() async {
    if (!await _confirm('Выйти из аккаунта?', 'Прогресс в этой версии не сохраняется на сервере и будет потерян.',
        'Выйти')) {
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _buildMain(),
            _buildModules(),
            _buildProgress(),
            _buildProfile(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(key: ValueKey('nav-home'), icon: Text('🏠'), label: 'Главная'),
          NavigationDestination(key: ValueKey('nav-modules'), icon: Text('📚'), label: 'Модули'),
          NavigationDestination(key: ValueKey('nav-progress'), icon: Text('📈'), label: 'Прогресс'),
          NavigationDestination(key: ValueKey('nav-profile'), icon: Text('👤'), label: 'Профиль'),
        ],
      ),
    );
  }

  // ---------- Главная ----------

  Widget _buildMain() {
    final p = widget.profile;
    final target = p.reserveTarget;
    final reserveShare = target == 0 ? 0.0 : (_savings / target).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(profile: p, points: _points),
        const SizedBox(height: 14),
        Row(
          children: [
            _Stat(label: 'Баланс', value: formatMoney(_balance)),
            const SizedBox(width: 8),
            _Stat(label: 'Накопления', value: formatMoney(_savings)),
            const SizedBox(width: 8),
            _Stat(label: 'Долг', value: formatMoney(_debt), alert: _debt > 0),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
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
                    target == 0
                        ? 'Укажите обязательные расходы, чтобы рассчитать цель резерва'
                        : 'Накоплено ${(reserveShare * 100).round()}% от цели',
                    style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          key: const ValueKey('continue-game'),
          onPressed: _openScenario,
          child: Text(_budgetDone ? 'Продолжить игру · месяц ${_history.length + 1}' : 'Начать игру'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Модули', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
            ),
            TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('Все')),
          ],
        ),
        const SizedBox(height: 4),
        for (final m in _modules)
          _ModuleCard(module: m, progress: _moduleProgress(m), onTap: () => _openModule(m)),
      ],
    );
  }

  // ---------- Модули ----------

  Widget _buildModules() {
    final done = _modules.where((m) => _moduleProgress(m) >= 1).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Модули', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Пройдено $done из ${_modules.length}. Каждый модуль — набор жизненных ситуаций с выбором решений.',
          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (final m in _modules)
          _ModuleCard(module: m, progress: _moduleProgress(m), onTap: () => _openModule(m)),
      ],
    );
  }

  // ---------- Прогресс ----------

  Widget _buildProgress() {
    final good = _history.fold<int>(0, (s, r) => s + r.goodDecisions);
    final total = _history.fold<int>(0, (s, r) => s + r.totalDecisions);
    final errorCounts = <String, int>{};
    for (final r in _history) {
      for (final e in r.errors) {
        errorCounts[e] = (errorCounts[e] ?? 0) + 1;
      }
    }
    final sortedErrors = errorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final target = widget.profile.reserveTarget;
    final reserveShare = target == 0 ? 0.0 : (_savings / target).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Прогресс', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(label: 'Очки', value: '$_points', alert: _points < 0),
            const SizedBox(width: 8),
            _Stat(label: 'Месяцев сыграно', value: '${_history.length}'),
            const SizedBox(width: 8),
            _Stat(
              label: 'Хороших решений',
              value: total == 0 ? '—' : '${(good * 100 / total).round()}%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Резервный фонд', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: reserveShare),
                const SizedBox(height: 6),
                Text(
                  '${formatMoney(_savings)} из ${formatMoney(target)} · ${(reserveShare * 100).round()}%',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('История', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        if (_history.isEmpty)
          _EmptyHint(
            text: 'Вы ещё не прошли ни одного сценария.',
            action: 'Начать игру',
            onPressed: _openScenario,
          ),
        for (var i = _history.length - 1; i >= 0; i--) _HistoryCard(month: i + 1, result: _history[i]),
        if (sortedErrors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Частые ошибки', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in sortedErrors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text('• ${e.key}')),
                          Text('×${e.value}', style: TextStyle(color: AppColors.muted(context))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- Профиль ----------

  Widget _buildProfile() {
    final p = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: p.avatar.shirt,
            child: Text(p.avatar.emoji, style: const TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(p.name, key: const ValueKey('profile-name'), style: Theme.of(context).textTheme.titleLarge),
        ),
        Center(
          child: Text('Очки: $_points', style: TextStyle(color: AppColors.muted(context))),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Финансы в месяц', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _PlanRow('Доход', formatMoney(p.income)),
                _PlanRow('Обязательные расходы', formatMoney(p.expenses)),
                _PlanRow('Свободно', formatMoney(p.free)),
                const Divider(height: 20),
                const Text('На старте игры', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _PlanRow('Накопления', formatMoney(p.savings)),
                _PlanRow('Долги', formatMoney(p.debt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('reset-progress'),
          onPressed: _resetProgress,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Сбросить прогресс'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('logout'),
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: AppColors.bad),
          label: const Text('Выйти из аккаунта', style: TextStyle(color: AppColors.bad)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.points});

  final UserProfile profile;
  final int points;

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
          CircleAvatar(
            radius: 30,
            backgroundColor: profile.avatar.shirt,
            child: Text(profile.avatar.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Здравствуйте,', style: TextStyle(color: Colors.white70)),
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text('Очки: $points', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.alert = false});

  final String label;
  final String value;

  /// Подсветить значение красным (долг, отрицательные очки).
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: alert ? AppColors.bad : null,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(label, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
              ),
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
          Expanded(child: Text(label, style: TextStyle(color: AppColors.muted(context), fontSize: 14))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.progress, required this.onTap});

  final _Module module;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final muted = AppColors.muted(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: module.available ? 1 : 0.6,
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
                          Text(module.desc, style: TextStyle(color: muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(module.available ? '$percent%' : 'Скоро', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.month, required this.result});

  final int month;
  final ScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final pts = result.points;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Месяц $month · Конец месяца', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${pts > 0 ? '+' : ''}$pts',
                  style: TextStyle(fontWeight: FontWeight.w700, color: pts >= 0 ? AppColors.ok : AppColors.bad),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Хороших решений: ${result.goodDecisions} из ${result.totalDecisions}',
              style: TextStyle(color: AppColors.muted(context), fontSize: 13),
            ),
            Text(
              'Итог: баланс ${formatMoney(result.balance)} · накопления ${formatMoney(result.savings)} · '
              'долг ${formatMoney(result.debt)}',
              style: TextStyle(color: AppColors.muted(context), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.action, required this.onPressed});

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted(context))),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
