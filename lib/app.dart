import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'themes/app_theme.dart';

class HinduConnectApp extends StatelessWidget {
    final String? initialLink;
  const HinduConnectApp({super.key, this.initialLink});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      onGenerateRoute: onGenerateRoute,
      initialRoute: '/',
    );
  }
}
