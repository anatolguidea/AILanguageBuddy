import 'package:flutter/material.dart';

/// Full-screen auth layout (design.md: dark_sign_i, dark_create, etc. — 430×932, light/dark).
/// Reusable shell: title, optional back, scrollable body, and optional footer link.
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.showBackButton = true,
    this.onBack,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(children),
              ),
            ),
            if (footer != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: footer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
