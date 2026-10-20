import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'onboarding_finance_screen.dart';

/// Шаг 1 онбординга: выбор персонажа и имени. Соответствует экрану «Создайте персонажа» в прототипе.
class OnboardingAvatarScreen extends StatefulWidget {
  const OnboardingAvatarScreen({super.key, required this.name});

  final String name;

  @override
  State<OnboardingAvatarScreen> createState() => _OnboardingAvatarScreenState();
}

class _OnboardingAvatarScreenState extends State<OnboardingAvatarScreen> {
  late final TextEditingController _nameController;
  int _avatarIndex = 0;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Введите имя в игре');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingFinanceScreen(name: name, avatarIndex: _avatarIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = avatarPresets[_avatarIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Создайте персонажа')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: preset.shirt,
                child: Text(preset.emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < avatarPresets.length; i++)
                  InkWell(
                    key: ValueKey('avatar-$i'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _avatarIndex = i),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarPresets[i].shirt,
                        border: Border.all(
                          width: 3,
                          color: i == _avatarIndex ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(avatarPresets[i].emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('name-field'),
              controller: _nameController,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: 'Имя в игре',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('avatar-next'),
              onPressed: _next,
              child: const Text('Далее: финансы'),
            ),
          ],
        ),
      ),
    );
  }
}
