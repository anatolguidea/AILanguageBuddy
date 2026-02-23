import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/auth_text_field.dart';
import 'auth_state.dart';
import 'sign_in_screen.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          );
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        // When email confirmation is disabled in Supabase, session is set and user is already signed in.
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.forLocale(ref.read(appLocaleProvider)).checkEmailConfirm)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.forLocale(ref.read(appLocaleProvider)).accountCreated)),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    return AuthScreenLayout(
      title: s.createAccount,
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
                controller: _nameController,
                label: s.nameOptional,
                hint: s.yourName,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: s.email,
                hint: s.youExampleCom,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.enterYourEmail;
                  if (!v.contains('@')) return s.enterValidEmail;
                  return null;
                },
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: s.password,
                hint: s.atLeast6Chars,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.length < 6) return s.passwordMin6;
                  return null;
                },
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 24),
              AppButton(label: s.createAccount, onPressed: _submit, loading: _loading),
            ],
          ),
        ),
      ],
      footer: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('${s.alreadyHaveAccount} ${s.logIn}'),
      ),
    );
  }
}
