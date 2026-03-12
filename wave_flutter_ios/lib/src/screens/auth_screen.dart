import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/session_controller.dart';

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF03152E),
              scheme.primary.withValues(alpha: 0.9),
              const Color(0xFF7ED5C8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Wave Messenger',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Android-клиент для backend из этого репозитория с тем же cookie login и realtime чатом.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: session.status == SessionStatus.awaitingTwoFactor
                            ? _buildTwoFactorCard(session)
                            : _buildAuthCard(session),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(SessionController session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_AuthMode>(
          segments: const [
            ButtonSegment<_AuthMode>(
              value: _AuthMode.login,
              label: Text('Вход'),
              icon: Icon(Icons.login_rounded),
            ),
            ButtonSegment<_AuthMode>(
              value: _AuthMode.register,
              label: Text('Регистрация'),
              icon: Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: session.busy
              ? null
              : (selection) {
                  setState(() {
                    _mode = selection.first;
                  });
                },
        ),
        const SizedBox(height: 18),
        if (_mode == _AuthMode.login) ...[
          TextField(
            controller: _loginController,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Логин или email',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            onSubmitted: (_) => _submitLogin(session),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: session.busy ? null : () => _submitLogin(session),
            icon: session.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: const Text('Войти'),
          ),
        ] else ...[
          TextField(
            controller: _registerUsernameController,
            decoration: const InputDecoration(
              labelText: 'Логин',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _registerPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.key_rounded),
            ),
            onSubmitted: (_) => _submitRegister(session),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: session.busy ? null : () => _submitRegister(session),
            icon: session.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.rocket_launch_rounded),
            label: const Text('Создать аккаунт'),
          ),
        ],
        if ((session.errorMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            session.errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTwoFactorCard(SessionController session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.shield_moon_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          'Подтверждение входа',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Аккаунт защищён двухфакторной авторизацией. Введи 6-значный код.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Код 2FA',
            counterText: '',
            prefixIcon: Icon(Icons.password_rounded),
          ),
          onSubmitted: (_) => _submitOtp(session),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: session.busy ? null : () => _submitOtp(session),
          icon: session.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_rounded),
          label: const Text('Подтвердить'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: session.busy ? null : session.resetTwoFactorFlow,
          child: const Text('Назад'),
        ),
        if ((session.errorMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            session.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submitLogin(SessionController session) async {
    await session.login(
      login: _loginController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _submitRegister(SessionController session) async {
    await session.register(
      username: _registerUsernameController.text,
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
    );
  }

  Future<void> _submitOtp(SessionController session) async {
    await session.submitTwoFactorCode(_otpController.text);
  }
}
