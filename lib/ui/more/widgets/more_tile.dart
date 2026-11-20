import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";

class MoreTile extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: PhosphorIcon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          const PhosphorIcon(PhosphorIconsDuotone.caretRight),
        ],
      ),
      onTap: onTap,
    );
  }
}
