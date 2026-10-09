import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PusatInformasiScreen extends StatefulWidget {
  const PusatInformasiScreen({super.key});

  @override
  State<PusatInformasiScreen> createState() => _PusatInformasiScreenState();
}

class _PusatInformasiScreenState extends State<PusatInformasiScreen> {
  List<dynamic> _allInfo = [];
  bool _isLoading = true;

  // Variabel untuk Filter & Search
  String _searchQuery = '';
  String _selectedType = 'semua';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getInformasi();
      setState(() {
        _allInfo = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memfilter data berdasarkan Kategori & Pencarian Teks
  List<dynamic> get _filteredInfo {
    return _allInfo.where((item) {
      // 1. Cek Filter Tipe
      bool matchesType = true;
      if (_selectedType != 'semua') {
        String itemType = (item['tipe'] ?? '').toString().toLowerCase();
        matchesType = itemType.contains(_selectedType);
      }

      // 2. Cek Pencarian Teks
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        String searchLower = _searchQuery.toLowerCase();
        String judul = (item['judul'] ?? '').toString().toLowerCase();
        String konten = (item['konten'] ?? '').toString().toLowerCase();
        matchesSearch = judul.contains(searchLower) || konten.contains(searchLower);
      }

      return matchesType && matchesSearch;
    }).toList();
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari judul atau isi informasi...',
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['semua', 'pengumuman', 'aturan'].map((tipe) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tipe.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: _selectedType == tipe,
                    selectedColor: Colors.blue[100],
                    backgroundColor: Colors.grey[200],
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedType = tipe;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedInfo = _filteredInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Informasi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedInfo.isEmpty
                    ? const Center(child: Text('Tidak ada informasi ditemukan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: displayedInfo.length,
                        itemBuilder: (context, index) {
                          final item = displayedInfo[index];
                          String tipeInfo = (item['tipe'] ?? 'UMUM').toString().toUpperCase();
                          
                          // Memberikan warna berbeda berdasarkan tipe informasi
                          Color labelBgColor = Colors.blue[50]!;
                          Color labelTextColor = Colors.blue;
                          
                          if (tipeInfo.contains('ATURAN')) {
                            labelBgColor = Colors.orange[50]!;
                            labelTextColor = Colors.orange;
                          } else if (tipeInfo.contains('PENTING')) {
                            labelBgColor = Colors.red[50]!;
                            labelTextColor = Colors.red;
                          }

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
                                      color: labelBgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tipeInfo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: labelTextColor,
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
                      ),
          ),
        ],
      ),
    );
  }
}