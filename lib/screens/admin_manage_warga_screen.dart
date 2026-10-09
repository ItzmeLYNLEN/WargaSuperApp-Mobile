import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminManageWargaScreen extends StatefulWidget {
  const AdminManageWargaScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageWargaScreen> createState() => _AdminManageWargaScreenState();
}

class _AdminManageWargaScreenState extends State<AdminManageWargaScreen> {
  List<dynamic> wargaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWargaData();
  }

  Future<void> _loadWargaData() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/admin/warga'));
      if (res.statusCode == 200) {
        setState(() {
          wargaList = json.decode(res.body)['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showEditWargaForm(Map<String, dynamic> item) {
    final namaController = TextEditingController(text: item['nama']);
    final noWaController = TextEditingController(text: item['no_wa']);
    final blokController = TextEditingController(text: item['blok_rumah']);
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Data Warga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: noWaController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                  const SizedBox(height: 12),
                  TextField(controller: blokController, decoration: const InputDecoration(labelText: 'Blok Rumah', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home))),
                  const SizedBox(height: 12),
                  TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru (Kosongkan jika tidak diubah)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: isSubmitting ? null : () async {
                        if (namaController.text.isEmpty || noWaController.text.isEmpty) return;
                        setModalState(() => isSubmitting = true);
                        try {
                          final response = await http.put(
                            Uri.parse('http://10.0.2.2:3000/api/admin/warga/${item['id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({
                              'nama': namaController.text,
                              'no_wa': noWaController.text,
                              'blok_rumah': blokController.text,
                              'password': passwordController.text,
                            }),
                          );
                          if (response.statusCode == 200 && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Data warga diupdate!'), backgroundColor: Colors.green));
                            _loadWargaData();
                            Navigator.pop(modalContext);
                          }
                        } catch (e) {} finally {
                          if (mounted) setModalState(() => isSubmitting = false);
                        }
                      },
                      child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Perubahan'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus data warga ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final res = await http.delete(Uri.parse('http://10.0.2.2:3000/api/admin/warga/$id'));
              if (res.statusCode == 200) {
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Data warga dihapus!'), backgroundColor: Colors.green));
                _loadWargaData();
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manajemen Data Warga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : wargaList.isEmpty 
          ? const Center(child: Text('Belum ada data warga.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wargaList.length,
              itemBuilder: (context, index) {
                final item = wargaList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Blok: ${item['blok_rumah']}'),
                        const SizedBox(height: 4),
                        Text('WA: ${item['no_wa']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditWargaForm(item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}