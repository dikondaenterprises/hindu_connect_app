import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  const TopBar({super.key, required this.title, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack ? const BackButton() : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.deepOrange,
      elevation: 4,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
