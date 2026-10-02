import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _tagihanFuture;
  List<int> _cart = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _tagihanFuture = ApiService.getTagihan(widget.userData['id'].toString());
      _cart.clear();
    });
  }

  void _toggleCart(int tagihanId) {
    setState(() {
      if (_cart.contains(tagihanId)) {
        _cart.remove(tagihanId);
      } else {
        _cart.add(tagihanId);
      }
    });
  }

  void _prosesCheckout(List<int> tagihanIds) async {
    setState(() => _isLoading = true);
    final result = await ApiService.checkout(widget.userData['id'].toString(), tagihanIds);
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['status'] == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Halo, ${widget.userData['nama']} 👋'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Badge(
                  label: Text(_cart.length.toString()),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _prosesCheckout(_cart),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : FutureBuilder<List<dynamic>>(
              future: _tagihanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada tagihan bulan ini. Hore! 🎉'));
                }

                final tagihanList = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tagihanList.length,
                  itemBuilder: (context, index) {
                    final item = tagihanList[index];
                    final bulanNama = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"][item['bulan'] - 1];
                    final isLunas = item['status_pembayaran'] == 'lunas';
                    
                    bool isDisabled = false;
                    if (!isLunas) {
                      for (int i = 0; i < index; i++) {
                        if (tagihanList[i]['status_pembayaran'] == 'belum_bayar') {
                          isDisabled = true;
                          break;
                        }
                      }
                    }

                    final inCart = _cart.contains(item['tagihan_id']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isLunas ? Colors.green[50] : Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item['nama_kategori']} - $bulanNama ${item['tahun']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (isLunas)
                                  const Icon(Icons.check_circle, color: Colors.green)
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${item['nominal']}',
                              style: TextStyle(
                                color: isLunas ? Colors.green : Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isLunas) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDisabled ? Colors.grey : Colors.blue,
                                      ),
                                      onPressed: isDisabled ? null : () => _prosesCheckout([item['tagihan_id']]),
                                      child: const Text('Bayar Langsung', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDisabled ? Colors.grey[200] : (inCart ? Colors.red[50] : Colors.blue[50]),
                                    ),
                                    icon: Icon(
                                      inCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                                      color: isDisabled ? Colors.grey : (inCart ? Colors.red : Colors.blue),
                                    ),
                                    onPressed: isDisabled ? null : () => _toggleCart(item['tagihan_id']),
                                  ),
                                ],
                              )
                            ]
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