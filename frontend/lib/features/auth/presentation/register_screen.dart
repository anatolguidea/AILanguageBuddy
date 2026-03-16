import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/auth_text_field.dart';
import 'auth_state.dart';
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
    if (!_formKey.currentState!.validate()) {
      final locale = ref.read(appLocaleProvider);
      final isRo = locale.toLowerCase().startsWith('ro');
      SemanticsService.announce(
        isRo
            ? 'Formular invalid. Verificați câmpurile.'
            : 'Invalid form. Check all fields.',
        Directionality.of(context),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        // When email confirmation is disabled in Supabase, session is set and user is already signed in.
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.forLocale(
                  ref.read(appLocaleProvider),
                ).checkEmailConfirm,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.forLocale(
                  ref.read(appLocaleProvider),
                ).accountCreated,
              ),
            ),
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
    final isRo = locale.toLowerCase().startsWith('ro');
    return AuthScreenLayout(
      title: s.createAccount,
      children: [
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
        ],
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Semantics(
                    textField: true,
                    label: isRo
                        ? 'Câmp introducere nume opțional'
                        : 'Optional name input field',
                    child: AuthTextField(
                      controller: _nameController,
                      label: s.nameOptional,
                      hint: s.yourName,
                      keyboardType: TextInputType.name,
                      autofillHints: const [AutofillHints.name],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: Semantics(
                    textField: true,
                    label: isRo
                        ? 'Câmp introducere email'
                        : 'Email input field',
                    child: AuthTextField(
                      controller: _emailController,
                      label: s.email,
                      hint: s.youExampleCom,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          SemanticsService.announce(
                            isRo
                                ? 'Introduceți adresa de email.'
                                : 'Please enter your email.',
                            Directionality.of(context),
                          );
                          return s.enterYourEmail;
                        }
                        if (!v.contains('@')) {
                          SemanticsService.announce(
                            isRo
                                ? 'Format email invalid.'
                                : 'Invalid email format.',
                            Directionality.of(context),
                          );
                          return s.enterValidEmail;
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.email],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: Semantics(
                    textField: true,
                    obscured: true,
                    label: isRo
                        ? 'Câmp introducere parolă'
                        : 'Password input field',
                    child: AuthTextField(
                      controller: _passwordController,
                      label: s.password,
                      hint: s.atLeast6Chars,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          SemanticsService.announce(
                            isRo
                                ? 'Parolă prea scurtă.'
                                : 'Password is too short.',
                            Directionality.of(context),
                          );
                          return s.passwordMin6;
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: Semantics(
                    button: true,
                    label: isRo ? 'Buton înregistrare' : 'Register button',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: AppButton(
                        label: s.createAccount,
                        onPressed: _submit,
                        loading: _loading,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      footer: Semantics(
        button: true,
        label: isRo ? 'Link: Ai deja cont? Autentifică-te' : 'Login link',
        child: TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('${s.alreadyHaveAccount} ${s.logIn}'),
        ),
      ),
    );
  }
}
