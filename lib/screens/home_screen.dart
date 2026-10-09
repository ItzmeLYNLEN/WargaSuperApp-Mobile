import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'webview_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> tagihanList = [];
  List<int> _cart = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/tagihan/${widget.userData['id']}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tagihanList = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleCart(int tagihanId) {
    setState(() {
      if (_cart.contains(tagihanId)) {
        _cart.clear();
      } else {
        _cart.add(tagihanId);
      }
    });
  }

  Future<void> _checkout(List<int> tagihanIds) async {
    if (tagihanIds.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('https://harmony-vigorous-immunize.ngrok-free.dev/api/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData['id'],
          'tagihan_ids': tagihanIds,
        }),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final redirectUrl = data['data']['redirect_url'];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: redirectUrl),
            ),
          ).then((_) {
            _loadData();
            setState(() {
              _cart.clear();
            });
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal checkout: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Koneksi Error: $e')),
        );
      }
    }
  }

  Widget _buildRingkasan() {
    double totalBelum = 0;
    double totalLunas = 0;
    int countBelum = 0;

    for (var item in tagihanList) {
      double nominal = double.parse(item['nominal'].toString());
      if (item['status_pembayaran'] == 'lunas') {
        totalLunas += nominal;
      } else {
        totalBelum += nominal;
        countBelum++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Halo, ${widget.userData['nama']} 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selamat datang di portal warga. Berikut adalah ringkasan tagihan iuran Anda:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.red[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Belum Dibayar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Rp ${totalBelum.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        if (countBelum > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('$countBelum tagihan menunggu pembayaran', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sudah Dibayar (Lunas)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Rp ${totalLunas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarTagihan(bool isLunas) {
    final filteredList = tagihanList.where((item) => (item['status_pembayaran'] == 'lunas') == isLunas).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          isLunas ? 'Belum ada riwayat pembayaran lunas.' : 'Hore! Semua tagihan sudah lunas.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final inCart = _cart.contains(item['tagihan_id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['nama_kategori']} - ${item['bulan']} ${item['tahun']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Rp ${double.parse(item['nominal'].toString()).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                const SizedBox(height: 16.0),
                if (isLunas)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                    child: const Text('LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: inCart ? null : () => _checkout([item['tagihan_id']]),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inCart ? Colors.grey[300] : const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          child: const Text('Bayar Langsung'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      InkWell(
                        onTap: () => _toggleCart(item['tagihan_id']),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: inCart ? Colors.blue : const Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                            color: inCart ? Colors.white : const Color(0xFF2196F3),
                            size: 20.0,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text('Dasbor Warga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Belum Bayar'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRingkasan(),
                _buildDaftarTagihan(false),
                _buildDaftarTagihan(true),
              ],
            ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _checkout(_cart),
              label: Text('Checkout (${_cart.length})'),
              icon: const Icon(Icons.payment),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}