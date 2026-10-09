import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class LayananScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LayananScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _kategoriController = TextEditingController();
  final _lokasiController = TextEditingController();
  bool _isSubmittingFasum = false;

  final _namaTamuController = TextEditingController();
  final _lamaMenginapController = TextEditingController();
  final _pelatController = TextEditingController();
  bool _isSubmittingTamu = false;

  List<dynamic> riwayatFasum = [];
  bool isLoadingRiwayat = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => isLoadingRiwayat = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/lapor-fasum/riwayat/${widget.userData['id']}'));
      if (res.statusCode == 200) {
        setState(() => riwayatFasum = json.decode(res.body)['data']);
      }
    } catch (e) {} finally {
      setState(() => isLoadingRiwayat = false);
    }
  }

  Future<void> _submitFasum() async {
    if (_kategoriController.text.isEmpty || _lokasiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmittingFasum = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/lapor-fasum'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData['id'],
          'kategori': _kategoriController.text,
          'deskripsi_lokasi': _lokasiController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim!'), backgroundColor: Colors.green));
        _kategoriController.clear();
        _lokasiController.clear();
        _fetchRiwayat();
        _tabController.animateTo(2);
      }
    } catch (e) {
    } finally {
      setState(() => _isSubmittingFasum = false);
    }
  }

  Future<void> _submitTamu() async {
    if (_namaTamuController.text.isEmpty || _lamaMenginapController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan lama menginap wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmittingTamu = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/lapor-tamu'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData['id'],
          'nama_tamu': _namaTamuController.text,
          'lama_menginap_hari': _lamaMenginapController.text,
          'pelat_kendaraan': _pelatController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan tamu berhasil dikirim!'), backgroundColor: Colors.green));
        _namaTamuController.clear();
        _lamaMenginapController.clear();
        _pelatController.clear();
      }
    } catch (e) {
    } finally {
      setState(() => _isSubmittingTamu = false);
    }
  }

  Widget _buildTimelineItem(String label, IconData icon, bool isActive, bool isPast) {
    Color color = isActive || isPast ? Colors.blue : Colors.grey[300]!;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.blue : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Warga', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.broken_image), text: 'Fasum'),
            Tab(icon: Icon(Icons.person_add), text: 'Tamu'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Form Pengaduan Fasilitas Umum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Laporkan kerusakan fasilitas umum di lingkungan RT.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _kategoriController,
                  decoration: const InputDecoration(labelText: 'Kategori Kerusakan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lokasiController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Patokan Lokasi', border: OutlineInputBorder(), alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isSubmittingFasum ? const SizedBox.shrink() : const Icon(Icons.send, color: Colors.white),
                    label: _isSubmittingFasum ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Laporan', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isSubmittingFasum ? null : _submitFasum,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Form Tamu Menginap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Wajib lapor 1x24 jam untuk tamu yang bermalam.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _namaTamuController,
                  decoration: const InputDecoration(labelText: 'Nama Tamu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lamaMenginapController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lama Menginap (Hari)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pelatController,
                  decoration: const InputDecoration(labelText: 'Pelat Kendaraan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isSubmittingTamu ? const SizedBox.shrink() : const Icon(Icons.send, color: Colors.white),
                    label: _isSubmittingTamu ? const CircularProgressIndicator(color: Colors.white) : const Text('Lapor Tamu', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isSubmittingTamu ? null : _submitTamu,
                  ),
                ),
              ],
            ),
          ),
          isLoadingRiwayat
              ? const Center(child: CircularProgressIndicator())
              : riwayatFasum.isEmpty
                  ? const Center(child: Text('Belum ada riwayat laporan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: riwayatFasum.length,
                      itemBuilder: (context, index) {
                        final item = riwayatFasum[index];
                        String status = item['status'] ?? 'menunggu';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['kategori'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(item['deskripsi_lokasi'], style: const TextStyle(color: Colors.grey)),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTimelineItem('Menunggu', Icons.hourglass_empty, status == 'menunggu', true),
                                    Expanded(child: Divider(color: status == 'proses' || status == 'selesai' ? Colors.blue : Colors.grey[300], thickness: 2)),
                                    _buildTimelineItem('Diproses', Icons.build, status == 'proses', status == 'selesai'),
                                    Expanded(child: Divider(color: status == 'selesai' ? Colors.blue : Colors.grey[300], thickness: 2)),
                                    _buildTimelineItem('Selesai', Icons.check, status == 'selesai', status == 'selesai'),
                                  ],
                                ),
                                if (item['catatan_admin'] != null && item['catatan_admin'].toString().isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Catatan Admin:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(item['catatan_admin'], style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}