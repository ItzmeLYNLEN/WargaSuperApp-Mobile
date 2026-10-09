import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({Key? key}) : super(key: key);

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  List<dynamic> jadwalList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/jadwal'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jadwalList = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Fungsi memunculkan pop-up detail dan tombol file
  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['judul_kegiatan'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tanggal: ${item['tanggal_kegiatan'].toString().split('T')[0]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Jenis: ${item['jenis_kegiatan']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Tombol Lampiran
              if (item['file_lampiran'] != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Lihat/Unduh Lampiran File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // Gabungkan URL backend dengan path lampiran
                      final url = Uri.parse('http://10.0.2.2:3000${item['file_lampiran']}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tidak dapat membuka file')),
                        );
                      }
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: const Text(
                    'Tidak ada lampiran file untuk jadwal ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jadwalList.isEmpty
              ? const Center(child: Text('Belum ada jadwal yang disebar.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jadwalList.length,
                  itemBuilder: (context, index) {
                    final item = jadwalList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.event_note, color: Colors.white),
                        ),
                        title: Text(item['judul_kegiatan'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['tanggal_kegiatan'].toString().split('T')[0]}\n${item['jenis_kegiatan']}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => _showDetail(item),
                      ),
                    );
                  },
                ),
    );
  }
}