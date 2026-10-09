import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class JadwalScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const JadwalScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  List<dynamic> _allJadwal = [];
  bool _isLoading = true;

  // Variabel untuk Filter & Search
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/jadwal'));
      if (res.statusCode == 200) {
        setState(() {
          _allJadwal = json.decode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memfilter data berdasarkan Tanggal & Pencarian Teks
  List<dynamic> get _filteredJadwal {
    return _allJadwal.where((item) {
      // 1. Cek Filter Tanggal
      bool inRange = true;
      if (_selectedDateRange != null) {
        try {
          DateTime itemDate = DateTime.parse(item['tanggal_kegiatan'].toString().split('T')[0]);
          DateTime start = _selectedDateRange!.start;
          DateTime end = _selectedDateRange!.end.add(const Duration(days: 1)); 
          inRange = itemDate.isAfter(start.subtract(const Duration(days: 1))) && itemDate.isBefore(end);
        } catch (e) {
          inRange = true;
        }
      }

      // 2. Cek Pencarian Teks
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        String searchLower = _searchQuery.toLowerCase();
        String judul = (item['judul_kegiatan'] ?? '').toString().toLowerCase();
        String jenis = (item['jenis_kegiatan'] ?? '').toString().toLowerCase();
        matchesSearch = judul.contains(searchLower) || jenis.contains(searchLower);
      }

      return inRange && matchesSearch;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  Future<void> _bukaFileLampiran(String? fileName) async {
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File tidak tersedia')));
      return;
    }

    // Membersihkan dobel slash jika ada (mencegah error browser putih)
    String cleanFileName = fileName;
    if (cleanFileName.startsWith('/')) {
      cleanFileName = cleanFileName.substring(1);
    }

    final url = Uri.parse('http://10.0.2.2:3000/$cleanFileName');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka file/browser')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error membuka file: $e')));
    }
  }

  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['judul_kegiatan'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.purple, size: 20),
                  const SizedBox(width: 12),
                  Text('Tanggal: ${item['tanggal_kegiatan'].toString().split('T')[0]}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Text('Jenis: ${item['jenis_kegiatan']}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 24),
              if (item['file_lampiran'] != null && item['file_lampiran'].toString().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Lihat/Unduh Lampiran File'),
                    onPressed: () => _bukaFileLampiran(item['file_lampiran']),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedDateRange == null 
                    ? 'Semua Waktu' 
                    : '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} s/d ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: _clearDateFilter),
              OutlinedButton(onPressed: _pickDateRange, child: const Text('Pilih Tanggal')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau jenis kegiatan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data yang sudah difilter
    final displayedJadwal = _filteredJadwal;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedJadwal.isEmpty
                    ? const Center(child: Text('Tidak ada jadwal ditemukan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedJadwal.length,
                        itemBuilder: (context, index) {
                          final item = displayedJadwal[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.event, color: Colors.white)),
                              title: Text(item['judul_kegiatan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(item['tanggal_kegiatan'].toString().split('T')[0]),
                                  Text(item['jenis_kegiatan']),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => _showDetail(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}