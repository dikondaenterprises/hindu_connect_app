// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:hindu_connect_app/screens/connect/connect_page.dart';
import 'package:hindu_connect_app/screens/magazine/magazine_page.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forgot_password_page.dart';
import '../screens/auth/phone_verify_page.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_page.dart';
import '../screens/viewer/viewer_page.dart';
import '../screens/temples/temple_viewer_page.dart';
import '../screens/offline/offline_sync_page.dart';
import '../screens/admin/admin_panel.dart';

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case '/':
      page = const SplashScreen();
      break;
    case '/login':
      page = const LoginPage();
      break;
    case '/register':
      page = const RegisterPage();
      break;
    case '/forgot':
      page = const ForgotPasswordPage();
      break;
    case '/phoneVerify':
      page = const PhoneVerifyPage();
      break;
    case '/home':
      page = const HomeScreen();
      break;
    case '/search':
      page = SearchPage(langCode: settings.arguments as String);
      break;
    case '/viewer':
      page = ViewerPage(filePath: settings.arguments as String);
      break;
    case '/connect':
      page = ConnectPage(filePath: settings.arguments as String);
      break;
    case '/temple':
      page = TempleViewerPage(filePath: settings.arguments as String);
      break;
    case '/magazine':
      page = MagazinePage(filePath: settings.arguments as String);
      break;
    case '/offline':
      page = OfflineSyncPage(langCode: settings.arguments as String);
      break;
    case '/admin':
      page = const AdminPanel();
      break;
    default:
      page = const SplashScreen();
      break;
  }
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      );
    },
  );
}
