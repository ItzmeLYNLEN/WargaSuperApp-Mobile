import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PusatInformasiScreen extends StatefulWidget {
  const PusatInformasiScreen({super.key});

  @override
  State<PusatInformasiScreen> createState() => _PusatInformasiScreenState();
}

class _PusatInformasiScreenState extends State<PusatInformasiScreen> {
  late Future<List<dynamic>> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = ApiService.getInformasi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Informasi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<dynamic>>(
        future: _infoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada informasi.'));
          }

          final infoList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: infoList.length,
            itemBuilder: (context, index) {
              final item = infoList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['tipe'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.blue, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['judul'],
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['konten'],
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}