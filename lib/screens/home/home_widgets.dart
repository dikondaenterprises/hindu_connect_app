import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeWidgets extends StatefulWidget {
  const HomeWidgets({super.key});
  @override
  State<HomeWidgets> createState() => _HomeWidgetsState();
}

class _HomeWidgetsState extends State<HomeWidgets> {
  final PageController _carouselCtrl = PageController(viewportFraction: 0.8);
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _page = (_page + 1) % 5;
      _carouselCtrl.animateToPage(_page,
          duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel placeholder or trending stotras carousel
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _carouselCtrl,
            itemCount: 5,
            itemBuilder: (_, i) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('Slide ${i + 1}')),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Daily recommendation from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('daily_recommendation')
              .limit(1)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            final data = snap.data!.docs.first.data()! as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.star),
              title: Text(data['title'] ?? 'Today\'s Stotra'),
              subtitle: Text(data['file'] ?? ''),
              onTap: () => Navigator.pushNamed(context, '/viewer',
                  arguments: data['file'] as String),
            );
          },
        ),
      ],
    );
  }
}
