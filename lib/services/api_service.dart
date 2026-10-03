import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Map<String, dynamic>> login(String noWa, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'no_wa': noWa,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 404) {
        return jsonDecode(response.body); 
      } else {
        return {'status': false, 'message': 'Terjadi kesalahan pada server.'};
      }
    } catch (e) {
      print('Error Login API: $e');
      return {'status': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  static Future<List<dynamic>> getTagihan(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tagihan/$userId'));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true) {
          return result['data'];
        }
      }
      return [];
    } catch (e) {
      print('Error getTagihan: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> laporTamu(String userId, String namaTamu, int lamaMenginap, String pelat) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lapor-tamu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'nama_tamu': namaTamu,
          'lama_menginap_hari': lamaMenginap,
          'pelat_kendaraan': pelat,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> laporFasum(String userId, String kategori, String deskripsi) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lapor-fasum'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'kategori': kategori,
          'deskripsi_lokasi': deskripsi,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  static Future<List<dynamic>> getInformasi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/informasi'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true) {
          return result['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getJadwal() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jadwal'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true) {
          return result['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> checkout(String userId, List<int> tagihanIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'tagihan_ids': tagihanIds,
        }),
      );
      
      print('--- DEBUG CHECKOUT ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error Checkout API: $e');
      return {'status': false, 'message': 'Gagal terhubung: $e'};
    }
  }
}