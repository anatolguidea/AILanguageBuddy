import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/auth_text_field.dart';
import 'auth_state.dart';
import 'sign_in_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(_emailController.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
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

    if (_sent) {
      return AuthScreenLayout(
        title: s.checkYourEmail,
        children: [
          const SizedBox(height: 16),
          Text(
            '${s.weSentLink} ${_emailController.text.trim()}. '
            'Open the link to set a new password.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: s.backToSignIn,
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            ),
          ),
        ],
      );
    }
    return AuthScreenLayout(
      title: s.forgotPassword,
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
              Text(
                s.enterEmailResetLink,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              AppButton(label: s.sendResetLink, onPressed: _submit, loading: _loading),
            ],
          ),
        ),
      ],
    );
  }
}
