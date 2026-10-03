import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> tagihanList = [];
  List<int> _cart = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Munculkan loading agar terlihat ada proses berjalan saat tombol ditekan
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: Text(
          'Halo, ${widget.userData['nama']} 👋',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: tagihanList.length,
              itemBuilder: (context, index) {
                final item = tagihanList[index];
                final isLunas = item['status_pembayaran'] == 'lunas';

                bool isDisabled = false;
                if (!isLunas) {
                  for (int i = 0; i < index; i++) {
                    if (tagihanList[i]['status_pembayaran'] != 'lunas' &&
                        !_cart.contains(tagihanList[i]['tagihan_id'])) {
                      isDisabled = true;
                      break;
                    }
                  }
                }

                final inCart = _cart.contains(item['tagihan_id']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['nama_kategori']} - ${item['bulan']} ${item['tahun']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Rp ${double.parse(item['nominal'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        if (isLunas)
                          const Text(
                            'LUNAS',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isDisabled || inCart
                                      ? null 
                                      : () => _checkout([item['tagihan_id']]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDisabled || inCart
                                        ? Colors.grey[300]
                                        : const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  ),
                                  child: const Text('Bayar Langsung'),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              InkWell(
                                onTap: isDisabled ? null : () => _toggleCart(item['tagihan_id']),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? Colors.grey[200]
                                        : (inCart ? Colors.blue : const Color(0xFFE3F2FD)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                    color: isDisabled
                                        ? Colors.grey
                                        : (inCart ? Colors.white : const Color(0xFF2196F3)),
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
            ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _checkout(_cart),
              label: Text('Checkout (${_cart.length})'),
              icon: const Icon(Icons.payment),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
}