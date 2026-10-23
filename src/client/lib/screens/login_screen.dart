import 'package:flutter/material.dart';

import '../theme.dart';
import 'onboarding_avatar_screen.dart';

/// Экран входа и регистрации. Соответствует экрану входа прототипа.
/// Данные никуда не отправляются: это каркас, без сервера.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _registerMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      return 'Введите корректную почту';
    }
    return null;
  }

  String? _validatePass(String? value) {
    if ((value ?? '').length < 6) return 'Пароль не короче 6 символов';
    return null;
  }

  String? _validateName(String? value) {
    if (!_registerMode) return null;
    if ((value ?? '').trim().isEmpty) return 'Укажите имя';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final name = _registerMode ? _nameController.text.trim() : email.split('@').first;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OnboardingAvatarScreen(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 24),
                _Hero(),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _modeButton('Вход', !_registerMode, () => setState(() => _registerMode = false))),
                              const SizedBox(width: 8),
                              Expanded(child: _modeButton('Регистрация', _registerMode, () => setState(() => _registerMode = true))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_registerMode) ...[
                            Text('Имя и фамилия', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _nameController,
                              validator: _validateName,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text('Почта', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text('Пароль (не короче 6 символов)', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passController,
                            obscureText: true,
                            validator: _validatePass,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _submit,
                            child: Text(_registerMode ? 'Создать аккаунт' : 'Войти'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Каркас: данные хранятся только на устройстве и никуда не отправляются.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return selected
        ? FilledButton(onPressed: onTap, child: Text(label))
        : OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ФинИгра', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Принимайте финансовые решения без реальных потерь',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
