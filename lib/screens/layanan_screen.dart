import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LayananScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const LayananScreen({super.key, required this.userData});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> {
  final _namaTamuController = TextEditingController();
  final _lamaController = TextEditingController();
  final _pelatController = TextEditingController();

  final _deskripsiController = TextEditingController();
  String _selectedKategoriFasum = 'Lampu Jalan';
  final List<String> _kategoriFasum = ['Lampu Jalan', 'Jalan Rusak', 'Sampah', 'Keamanan', 'Lainnya'];

  bool _isLoading = false;

  void _submitLaporTamu() async {
    if (_namaTamuController.text.isEmpty || _lamaController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final result = await ApiService.laporTamu(
      widget.userData['id'].toString(),
      _namaTamuController.text,
      int.parse(_lamaController.text),
      _pelatController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    
    if (result['status'] == true) {
      _namaTamuController.clear();
      _lamaController.clear();
      _pelatController.clear();
    }
  }

  void _submitLaporFasum() async {
    if (_deskripsiController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final result = await ApiService.laporFasum(
      widget.userData['id'].toString(),
      _selectedKategoriFasum,
      _deskripsiController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['status'] == true) {
      _deskripsiController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Layanan Warga'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Lapor Tamu'),
              Tab(text: 'Lapor Fasum'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _namaTamuController,
                    decoration: const InputDecoration(labelText: 'Nama Tamu', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lamaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Lama Menginap (Hari)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pelatController,
                    decoration: const InputDecoration(labelText: 'Pelat Kendaraan (Opsional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isLoading ? null : _submitLaporTamu,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Laporan Tamu', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedKategoriFasum,
                    decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    items: _kategoriFasum.map((kategori) {
                      return DropdownMenuItem(value: kategori, child: Text(kategori));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedKategoriFasum = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deskripsiController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Deskripsi Lokasi / Kerusakan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isLoading ? null : _submitLaporFasum,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Laporan Fasum', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}