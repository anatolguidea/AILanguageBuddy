import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/auth_text_field.dart';
import 'auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _signInErrorMessage(e, AppStrings.forLocale(ref.read(appLocaleProvider)));
        });
      }
    }
  }

  /// Clearer messages for common Supabase auth errors.
  static String _signInErrorMessage(Object e, AppStringsData s) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
      return s.invalidEmailOrPassword;
    }
    if (msg.contains('email not confirmed') || msg.contains('confirm')) {
      return s.confirmEmailFirst;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    return AuthScreenLayout(
      title: s.signIn,
      showBackButton: false,
      children: [
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _emailController,
                label: s.email,
                hint: s.youExampleCom,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: s.password,
                hint: '••••••••',
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: Text(s.forgotPassword),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(label: s.signIn, onPressed: _submit, loading: _loading),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signInWithGoogle();
                },
                icon: const Icon(Icons.login), 
                label: Text(s.signInWithGoogle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
      footer: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: Text(s.dontHaveAccount),
      ),
    );
  }
}
