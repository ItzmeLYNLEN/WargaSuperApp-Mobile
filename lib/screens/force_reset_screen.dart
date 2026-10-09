import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_screen.dart';
import 'admin_screen.dart';

class ForceResetScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ForceResetScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ForceResetScreen> createState() => _ForceResetScreenState();
}

class _ForceResetScreenState extends State<ForceResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  Future<void> _submitPassword() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok!'), backgroundColor: Colors.red));
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/ganti-password/${widget.userData['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password_baru': _passwordController.text}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diamankan!'), backgroundColor: Colors.green));
          
          Map<String, dynamic> updatedUserData = Map.from(widget.userData);
          updatedUserData['wajib_ganti_password'] = 0;

          if (widget.userData['role'] == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminScreen(userData: updatedUserData)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(userData: updatedUserData)));
          }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah password'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Kunci tombol back bawaan HP
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.security, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text('Amankan Akun Anda', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('Ini adalah login pertama Anda. Demi keamanan, silakan ganti password default Anda dengan yang baru.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText1,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText1 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText1 = !_obscureText1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscureText2,
                    decoration: InputDecoration(
                      labelText: 'Ulangi Password Baru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText2 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText2 = !_obscureText2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _isLoading ? null : _submitPassword,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan & Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}