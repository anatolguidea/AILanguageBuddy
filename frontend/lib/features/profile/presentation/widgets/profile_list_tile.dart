import 'package:flutter/material.dart';

class ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const ProfileListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? scheme.onSurface;
    final effectiveTextColor = textColor ?? scheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: effectiveIconColor, size: 20),
      title: Text(title, style: TextStyle(color: effectiveTextColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)) : null,
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 16),
      onTap: onTap,
    );
  }
}
