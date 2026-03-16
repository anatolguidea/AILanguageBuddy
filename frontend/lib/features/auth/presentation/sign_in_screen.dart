import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    if (!_formKey.currentState!.validate()) {
      final locale = ref.read(appLocaleProvider);
      final isRo = locale.toLowerCase().startsWith('ro');
      SemanticsService.announce(
        isRo
            ? 'Formular invalid. Verificați emailul și parola.'
            : 'Invalid form. Check email and password.',
        Directionality.of(context),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(
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
          _error = _signInErrorMessage(
            e,
            AppStrings.forLocale(ref.read(appLocaleProvider)),
          );
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
    final isRo = locale.toLowerCase().startsWith('ro');
    return AuthScreenLayout(
      title: s.signIn,
      showBackButton: false,
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
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
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
                  order: const NumericFocusOrder(2),
                  child: Semantics(
                    textField: true,
                    obscured: true,
                    label: isRo
                        ? 'Câmp introducere parolă'
                        : 'Password input field',
                    child: AuthTextField(
                      controller: _passwordController,
                      label: s.password,
                      hint: '••••••••',
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          SemanticsService.announce(
                            isRo
                                ? 'Introduceți parola.'
                                : 'Please enter your password.',
                            Directionality.of(context),
                          );
                          return s.password;
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.password],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: isRo
                          ? 'Link: Parolă uitată'
                          : 'Forgot password link',
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(s.forgotPassword),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: Semantics(
                    button: true,
                    label: isRo ? 'Buton autentificare' : 'Login button',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: AppButton(
                        label: s.signIn,
                        onPressed: _submit,
                        loading: _loading,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: Semantics(
                    button: true,
                    label: isRo
                        ? 'Buton autentificare cu Google'
                        : 'Sign in with Google button',
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(authRepositoryProvider)
                            .signInWithGoogle();
                      },
                      icon: const Icon(Icons.login),
                      label: Text(s.signInWithGoogle),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(48, 48),
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
        label: isRo ? 'Link: Nu ai cont? Înregistrează-te' : 'Sign up link',
        child: TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: Text(s.dontHaveAccount),
        ),
      ),
    );
  }
}
