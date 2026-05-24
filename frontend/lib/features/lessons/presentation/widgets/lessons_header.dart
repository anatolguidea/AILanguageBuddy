import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/domain/entities/language.dart';
import '../../../settings/presentation/providers/language_provider.dart';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Language picker button
        _LanguageFlagButton(
          language: currentLanguage,
          onTap: () => _showLanguageSheet(context, ref),
        ),
        const SizedBox(width: 10),
        // Spacer pushes upgrade + streak to the right
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onUpgrade != null) ...[
              _UpgradeChip(
                label: upgradeLabel ?? 'Upgrade',
                onTap: onUpgrade!,
              ),
              const SizedBox(width: 8),
            ],
            _StreakBadge(count: streakCount),
          ],
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select language',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: Language.supported.map((lang) {
                      final isSelected = ref.read(languageProvider) == lang;
                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 26)),
                        title: Text(
                          lang.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: scheme.primary, size: 20)
                            : null,
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

class _UpgradeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _UpgradeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int count;

  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Select language: ${language.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.surfaceElevated : const Color(0xFFF4F4F5),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(language.flag, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}
