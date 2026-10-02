import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  late Future<List<dynamic>> _jadwalFuture;

  @override
  void initState() {
    super.initState();
    _jadwalFuture = ApiService.getJadwal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<dynamic>>(
        future: _jadwalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada jadwal kegiatan.'));
          }

          final jadwalList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final item = jadwalList[index];
              final tanggal = item['tanggal_kegiatan'].toString().split('T')[0];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.calendar_month, color: Colors.blue),
                  ),
                  title: Text(
                    item['judul_kegiatan'], 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    item['jenis_kegiatan'].toString().toUpperCase(),
                  ),
                  trailing: Text(
                    tanggal,
                    style: const TextStyle(
                      color: Colors.orange, 
                      fontWeight: FontWeight.bold
                    ),
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