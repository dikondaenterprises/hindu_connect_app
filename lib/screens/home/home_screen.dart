import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';
import 'home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: TopBar(title: 'Home'),
      bottomNavigationBar: BottomNav(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeWidgets(),
          ],
        ),
      ),
    );
  }
}
