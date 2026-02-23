import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/domain/entities/language.dart';
import '../../../settings/presentation/providers/language_provider.dart';

/// Header for Lessons screen: language selector (circle with flag), Upgrade, and streak.
class LessonsHeader extends ConsumerWidget {
  final int streakCount;
  final VoidCallback? onUpgrade;
  final String? upgradeLabel;

  const LessonsHeader({
    super.key,
    this.streakCount = 0,
    this.onUpgrade,
    this.upgradeLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return Row(
      children: [
        _LanguageFlagButton(
          language: currentLanguage,
          onTap: () => _showLanguageSheet(context, ref),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onUpgrade != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Material(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onUpgrade,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                upgradeLabel ?? 'Upgrade',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.accent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$streakCount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select language',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: Language.supported.map((lang) {
                      final isSelected = ref.read(languageProvider) == lang;
                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          lang.name,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected ? Icon(Icons.check, color: scheme.primary) : null,
                        onTap: () {
                          ref.read(languageProvider.notifier).setLanguage(lang);
                          Navigator.of(ctx).pop();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageFlagButton extends StatelessWidget {
  final Language language;
  final VoidCallback onTap;

  const _LanguageFlagButton({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.surfaceContainerHighest),
          ),
          alignment: Alignment.center,
          child: Text(language.flag, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
