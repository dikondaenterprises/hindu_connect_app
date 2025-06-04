import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        final routes = [
          '/home',
          '/search',
          '/connect',
          '/magazines',
          '/temples'
        ];
        Navigator.pushReplacementNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
            icon: Icon(Icons.video_collection), label: 'Connect'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Magazine'),
        BottomNavigationBarItem(
            icon: Icon(Icons.temple_buddhist), label: 'Temples'),
      ],
    );
  }
}
