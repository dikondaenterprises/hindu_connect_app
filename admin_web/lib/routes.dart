// admin_web/lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/stotras_section.dart';
import 'screens/temples_section.dart';
import 'screens/connect_section.dart';
import 'screens/magazines_section.dart';
import 'screens/notifications_section.dart';
import 'screens/role_manager_section.dart';
import 'screens/activity_log_section.dart';

class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
      case '/stotras':
        page = const StotrasSection();
        break;
      case '/temples':
        page = const TemplesSection();
        break;
      case '/connect':
        page = const ConnectSection();
        break;
      case '/magazines':
        page = const MagazinesSection();
        break;
      case '/notifications':
        page = const NotificationsSection();
        break;
      case '/roles':
        page = const RoleManagerSection();
        break;
      case '/logs':
        page = const ActivityLogSection();
        break;
      default:
        page = const StotrasSection();
        break;
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
