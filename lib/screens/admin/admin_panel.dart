import 'package:flutter/material.dart';
import 'stotras_admin_page.dart';
import 'temples_admin_page.dart';
import 'connect_admin_page.dart';
import 'magazine_admin_page.dart';
import 'notifications_admin_page.dart';
import 'role_manager.dart';
import 'activity_log_admin_page.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(
              title: const Text('Stotras'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StotrasAdminPage()))),
          ListTile(
              title: const Text('Temples'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TemplesAdminPage()))),
          ListTile(
              title: const Text('Connect Videos'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConnectAdminPage()))),
          ListTile(
              title: const Text('Magazine'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MagazineAdminPage()))),
          ListTile(
              title: const Text('Notifications'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsAdminPage()))),
          ListTile(
              title: const Text('Role Manager'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoleManager()))),
          ListTile(
              title: const Text('Activity Logs'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActivityLogAdminPage()))),
        ],
      ),
    );
  }
}
