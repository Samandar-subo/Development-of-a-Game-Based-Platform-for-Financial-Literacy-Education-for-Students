import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme.dart';
import '../utils/money.dart';

/// Итог сценария, который возвращается на главный экран.
class ScenarioResult {
  const ScenarioResult({
    required this.balance,
    required this.savings,
    required this.debt,
    required this.points,
    required this.goodDecisions,
    required this.totalDecisions,
    required this.errors,
  });

  final int balance;
  final int savings;
  final int debt;
  final int points;

  /// Сколько решений в сценарии было хорошими и сколько всего.
  final int goodDecisions;
  final int totalDecisions;

  /// Ошибки, допущенные в сценарии (без повторов).
  final List<String> errors;
}

class _Option {
  const _Option({
    required this.label,
    required this.points,
    required this.good,
    required this.why,
    this.error,
    this.next,
    this.apply,
  });

  final String label;
  final int points;
  final bool good;
  final String why;
  final String? error;

  /// Номер следующего шага; null — сценарий завершается.
  final int? next;

  /// Изменение состояния: получает текущие баланс, накопления и долг, возвращает новые.
  final _Effect Function(_State s)? apply;
}

class _Effect {
  const _Effect({required this.balance, required this.savings, required this.debt});
  final int balance;
  final int savings;
  final int debt;
}

class _State {
  _State({required this.balance, required this.savings, required this.debt});
  int balance;
  int savings;
  int debt;
  int points = 0;
}

class _LogEntry {
  _LogEntry({required this.question, required this.answer, required this.good, required this.why, required this.points, this.error});
  final String question;
  final String answer;
  final bool good;
  final String why;
  final int points;
  final String? error;
}

/// Сценарий «Конец месяца: остаток и резерв» — два шага с ветвлением.
/// Соответствует сценарию s1 прототипа.
class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key, required this.profile, required this.balance, required this.savings, required this.debt});

  final UserProfile profile;
  final int balance;
  final int savings;
  final int debt;

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  late final _State _state;
  late final List<_Step> _steps;
  int _step = 0;
  int? _chosen;
  final List<_LogEntry> _log = [];
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _state = _State(balance: widget.balance, savings: widget.savings, debt: widget.debt);
    _steps = _buildSteps(widget.profile.free);
  }

  List<_Step> _buildSteps(int free) {
    final save10 = (free * 0.1).round();
    return [
      _Step(
        text: 'После обязательных расходов у вас остаётся ${formatMoney(free)}. Как распределите деньги?',
        options: [
          _Option(
            label: 'Потрачу всё на развлечения и покупки',
            points: -5,
            good: false,
            error: 'нет резервного фонда',
            why: 'Резерва не осталось. Любая непредвиденная трата в следующем месяце станет долгом.',
            next: 1,
            apply: (s) => _Effect(balance: s.balance - free, savings: s.savings, debt: s.debt),
          ),
          _Option(
            label: 'Отложу 10% (${formatMoney(save10)}) на отдельный счёт, остальное оставлю на карте',
            points: 10,
            good: true,
            why: 'Резерв растёт, и он отделён от карты, поэтому его проще не трогать.',
            next: 1,
            apply: (s) => _Effect(balance: s.balance - save10, savings: s.savings + save10, debt: s.debt),
          ),
          _Option(
            label: 'Оставлю всё на карте, разберусь по ходу месяца',
            points: 2,
            good: false,
            error: 'нет резервного фонда',
            why: 'Деньги на карте незаметно тают. Резерв должен лежать на отдельном счёте.',
            next: 1,
            apply: (s) => _Effect(balance: s.balance, savings: s.savings, debt: s.debt),
          ),
        ],
      ),
      _Step(
        text: 'Сломался телефон. Ремонт стоит 18 000 ₸. Как поступите?',
        options: [
          _Option(
            label: 'Оплачу из накоплений, а если их нет — с карты',
            points: 8,
            good: true,
            why: 'Трата закрыта из своих денег: сначала из резерва, недостающее — с карты. '
                'Если и этого не хватило, остаток придётся занять — поэтому резерв так важен.',
            apply: (s) => _payFromOwn(s, 18000),
          ),
          _Option(
            label: 'Возьму микрокредит на 3 месяца под 3% в месяц',
            points: -10,
            good: false,
            error: 'неоправданное заимствование',
            why: 'Микрокредит 3% в месяц на 18 000 ₸ за 3 месяца даёт переплату ${formatMoney(1620)}: '
                'вернуть придётся ${formatMoney(19620)}. Проверьте, нельзя ли обойтись без займа.',
            apply: (s) => _Effect(balance: s.balance, savings: s.savings, debt: s.debt + 19620),
          ),
          _Option(
            label: 'Куплю ремонт в рассрочку «0%» на 6 месяцев',
            points: -3,
            good: false,
            error: 'неоправданное заимствование',
            why: '«0%» часто означает, что комиссия включена в цену. Сравните полную сумму с ценой за наличные.',
            apply: (s) => _Effect(balance: s.balance, savings: s.savings, debt: s.debt + 18000),
          ),
        ],
      ),
    ];
  }

  /// Оплата из своих денег: сначала накопления, затем карта, недостающее уходит в долг.
  static _Effect _payFromOwn(_State s, int cost) {
    var rest = cost;
    final fromSavings = rest < s.savings ? rest : s.savings;
    rest -= fromSavings;
    final fromBalance = rest < s.balance ? rest : s.balance;
    rest -= fromBalance;
    return _Effect(
      balance: s.balance - fromBalance,
      savings: s.savings - fromSavings,
      debt: s.debt + rest,
    );
  }

  _Step get _current => _steps[_step];

  void _choose(int index) {
    if (_chosen != null) return;
    final option = _current.options[index];
    final effect = option.apply?.call(_state) ??
        _Effect(balance: _state.balance, savings: _state.savings, debt: _state.debt);
    setState(() {
      _chosen = index;
      _state.balance = effect.balance < 0 ? 0 : effect.balance;
      _state.savings = effect.savings < 0 ? 0 : effect.savings;
      _state.debt = effect.debt < 0 ? 0 : effect.debt;
      _state.points += option.points;
      _log.add(_LogEntry(
        question: _current.text,
        answer: option.label,
        good: option.good,
        why: option.why,
        points: option.points,
        error: option.error,
      ));
    });
  }

  void _next() {
    final option = _current.options[_chosen!];
    if (option.next != null) {
      setState(() {
        _step = option.next!;
        _chosen = null;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  ScenarioResult _result() => ScenarioResult(
        balance: _state.balance,
        savings: _state.savings,
        debt: _state.debt,
        points: _state.points,
        goodDecisions: _log.where((e) => e.good).length,
        totalDecisions: _log.length,
        errors: _log.where((e) => e.error != null).map((e) => e.error!).toSet().toList(),
      );

  /// Выход из сценария. Итог применяется только к пройденному сценарию;
  /// при выходе посередине изменения отбрасываются (после подтверждения).
  Future<void> _exit() async {
    final navigator = Navigator.of(context);
    if (_finished) {
      navigator.pop(_result());
      return;
    }
    if (_log.isEmpty) {
      navigator.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из сценария?'),
        content: const Text('Сценарий не завершён. Выбранные решения не сохранятся.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Остаться')),
          TextButton(
            key: const ValueKey('scenario-leave'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<ScenarioResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Конец месяца'),
          leading: IconButton(
            key: const ValueKey('scenario-close'),
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
        ),
        body: SafeArea(
          child: _finished ? _buildResult() : _buildPlay(),
        ),
      ),
    );
  }

  Widget _buildPlay() {
    final picked = _chosen == null ? null : _current.options[_chosen!];
    final isLast = picked != null && picked.next == null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Шаг ${_step + 1} из ${_steps.length} · Баланс ${formatMoney(_state.balance)} · '
          'Накопления ${formatMoney(_state.savings)} · Долг ${formatMoney(_state.debt)}',
          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_current.text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
        for (var i = 0; i < _current.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton(
              key: ValueKey('option-$_step-$i'),
              onPressed: picked == null ? () => _choose(i) : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              child: Text(_current.options[i].label),
            ),
          ),
        if (picked != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(width: 4, color: picked.good ? AppColors.ok : AppColors.bad)),
              color: (picked.good ? AppColors.ok : AppColors.bad).withValues(alpha: 0.08),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(picked.good ? 'Хорошее решение' : 'Стоит пересмотреть',
                    key: const ValueKey('feedback-title'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(picked.why),
                const SizedBox(height: 6),
                Text(
                  'Очки: ${picked.points > 0 ? '+' : ''}${picked.points}${picked.error != null ? ' · ошибка: ${picked.error}' : ''}',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('scenario-next'),
            onPressed: _next,
            child: Text(isLast ? 'Посмотреть итог' : 'Продолжить'),
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final total = _log.fold<int>(0, (sum, e) => sum + e.points);
    final good = _log.where((e) => e.good).length;
    final errors = _log.where((e) => e.error != null).map((e) => e.error!).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Итог: Конец месяца', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Хороших решений: $good из ${_log.length}. Очки за сценарий: ${total > 0 ? '+' : ''}$total'),
        const SizedBox(height: 6),
        Text(
          'Баланс ${formatMoney(_state.balance)} · Накопления ${formatMoney(_state.savings)} · '
          'Долг ${formatMoney(_state.debt)}',
          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (final e in _log)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.question, style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(e.answer, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(e.why),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('На что обратить внимание', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (errors.isEmpty) const Text('Ошибок в этом сценарии не было.'),
                for (final e in errors) Text('• $e'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('scenario-finish'),
          onPressed: _exit,
          child: const Text('Вернуться домой'),
        ),
      ],
    );
  }
}

class _Step {
  const _Step({required this.text, required this.options});
  final String text;
  final List<_Option> options;
}
