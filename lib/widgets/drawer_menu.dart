import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        const DrawerHeader(
            decoration: BoxDecoration(color: Colors.orange),
            child: Text('Profile')),
        ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile')),
        ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () => Navigator.pushNamed(context, '/favorites')),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pushReplacementNamed(context, '/login')),
      ]),
    );
  }
}
