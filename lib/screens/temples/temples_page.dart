import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';

class TemplesPage extends StatefulWidget {
  const TemplesPage({super.key});
  @override
  State<TemplesPage> createState() => _TemplesPageState();
}

class _TemplesPageState extends State<TemplesPage> {
  final _fs = FirebaseFirestore.instance;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Temples'),
      bottomNavigationBar: const BottomNav(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search temples by name, village or district',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filter = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fs.collection('temples').orderBy('state').snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs.where((d) {
                  final m = d.data()! as Map<String, dynamic>;
                  return m['name'].toString().toLowerCase().contains(_filter) ||
                      m['state'].toString().toLowerCase().contains(_filter);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('No temples found.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data()! as Map<String, dynamic>;
                    final id = docs[i].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(d['name']),
                        subtitle: Text(d['state']),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(context, '/temple',
                              arguments: id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
