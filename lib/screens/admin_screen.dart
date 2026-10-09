import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'login_screen.dart';
import 'admin_manage_screen.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AdminScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDialOpen = false;
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _listBulan = [
    {'id': '1', 'nama': 'Januari'}, {'id': '2', 'nama': 'Februari'},
    {'id': '3', 'nama': 'Maret'}, {'id': '4', 'nama': 'April'},
    {'id': '5', 'nama': 'Mei'}, {'id': '6', 'nama': 'Juni'},
    {'id': '7', 'nama': 'Juli'}, {'id': '8', 'nama': 'Agustus'},
    {'id': '9', 'nama': 'September'}, {'id': '10', 'nama': 'Oktober'},
    {'id': '11', 'nama': 'November'}, {'id': '12', 'nama': 'Desember'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDial() {
    setState(() {
      _isDialOpen = !_isDialOpen;
      if (_isDialOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _refreshData() {
    setState(() {});
  }

  Future<Map<String, dynamic>> _fetchRekap() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/admin/rekap-kas'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        return data ?? {'total_kas_masuk': 0, 'total_transaksi_lunas': 0, 'total_transaksi_pending': 0};
      }
      throw Exception('Error status: ${res.statusCode}');
    } catch (e) {
      throw Exception('Gagal memuat data kas');
    }
  }

  Future<List<dynamic>> _fetchTamu() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/admin/laporan-tamu'));
    return json.decode(res.body)['data'];
  }

  Future<List<dynamic>> _fetchFasum() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/admin/laporan-fasum'));
    return json.decode(res.body)['data'];
  }

  Future<List<dynamic>> _fetchDaftarTagihan() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/admin/daftar-tagihan'));
    return json.decode(res.body)['data'];
  }

  String _getNamaBulan(String idBulan) {
    final bulan = _listBulan.firstWhere((element) => element['id'] == idBulan, orElse: () => {'nama': idBulan});
    return bulan['nama'];
  }

  void _showFormTambahInfo() {
    _toggleDial();
    final tipeController = TextEditingController();
    final judulController = TextEditingController();
    final kontenController = TextEditingController();
    PlatformFile? selectedFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Buat Pengumuman Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: tipeController, decoration: const InputDecoration(labelText: 'Tipe (Cth: Penting / Umum)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category))),
                    const SizedBox(height: 12),
                    TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Judul Pengumuman', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
                    const SizedBox(height: 12),
                    TextField(controller: kontenController, maxLines: 3, decoration: const InputDecoration(labelText: 'Isi Pengumuman', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'xlsx', 'xls'],
                            );
                            if (result != null) {
                              setModalState(() => selectedFile = result.files.first);
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Lampiran'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFile != null ? selectedFile!.name : 'Tidak ada file (opsional)',
                            style: TextStyle(color: selectedFile != null ? Colors.blue : Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => setModalState(() => selectedFile = null),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: isSubmitting ? null : () async {
                          if (tipeController.text.isEmpty || judulController.text.isEmpty || kontenController.text.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Semua kolom teks wajib diisi!'), backgroundColor: Colors.orange));
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:3000/api/admin/informasi'));
                            request.fields['tipe'] = tipeController.text;
                            request.fields['judul'] = judulController.text;
                            request.fields['konten'] = kontenController.text;
                            if (selectedFile != null && selectedFile!.path != null) {
                              request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path!));
                            }
                            var streamedResponse = await request.send();
                            var response = await http.Response.fromStream(streamedResponse);
                            if (response.statusCode == 201 && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Pengumuman berhasil disebar!'), backgroundColor: Colors.green));
                              Navigator.pop(modalContext);
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Gagal menyebar pengumuman'), backgroundColor: Colors.red));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Sebarkan Pengumuman'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showFormTambahJadwal() {
    _toggleDial();
    final judulController = TextEditingController();
    final jenisController = TextEditingController();
    DateTime? selectedDate;
    PlatformFile? selectedFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Buat Jadwal Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Nama Kegiatan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event))),
                    const SizedBox(height: 12),
                    TextField(controller: jenisController, decoration: const InputDecoration(labelText: 'Jenis (Cth: Rapat / Kerja Bakti)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.list))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(selectedDate == null ? 'Pilih Tanggal' : 'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}', style: TextStyle(color: selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
                              if (picked != null && picked != selectedDate) setModalState(() => selectedDate = picked);
                            },
                            child: const Text('Pilih'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'xlsx', 'xls'],
                            );
                            if (result != null) {
                              setModalState(() => selectedFile = result.files.first);
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Lampiran'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFile != null ? selectedFile!.name : 'Tidak ada file (opsional)',
                            style: TextStyle(color: selectedFile != null ? Colors.purple : Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => setModalState(() => selectedFile = null),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        onPressed: isSubmitting ? null : () async {
                          if (judulController.text.isEmpty || jenisController.text.isEmpty || selectedDate == null) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Judul, Jenis & Tanggal wajib diisi!'), backgroundColor: Colors.orange));
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            String formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                            var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:3000/api/admin/jadwal'));
                            request.fields['judul_kegiatan'] = judulController.text;
                            request.fields['jenis_kegiatan'] = jenisController.text;
                            request.fields['tanggal_kegiatan'] = formattedDate;
                            if (selectedFile != null && selectedFile!.path != null) {
                              request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path!));
                            }
                            var streamedResponse = await request.send();
                            var response = await http.Response.fromStream(streamedResponse);
                            if (response.statusCode == 201 && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil dibuat!'), backgroundColor: Colors.green));
                              Navigator.pop(modalContext);
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Gagal: ${response.body}'), backgroundColor: Colors.red));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Jadwal'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showFormTambahWarga() {
    _toggleDial();
    final namaController = TextEditingController();
    final noWaController = TextEditingController();
    final passwordController = TextEditingController();
    final blokController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tambah Warga Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 12),
                    TextField(controller: blokController, decoration: const InputDecoration(labelText: 'Blok Rumah (Cth: A1/12)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home))),
                    const SizedBox(height: 12),
                    TextField(controller: noWaController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 12),
                    TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Akun', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: isSubmitting ? null : () async {
                          if (namaController.text.isEmpty || noWaController.text.isEmpty || passwordController.text.isEmpty || blokController.text.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange));
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            final response = await http.post(
                              Uri.parse('http://10.0.2.2:3000/api/admin/tambah-warga'),
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({'nama': namaController.text, 'no_wa': noWaController.text, 'password': passwordController.text, 'blok_rumah': blokController.text, 'role': 'warga'}),
                            );
                            if (response.statusCode == 201 && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Warga berhasil ditambahkan'), backgroundColor: Colors.green));
                              Navigator.pop(modalContext);
                            }
                          } catch (e) {
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Data'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showFormTambahTagihan() {
    _toggleDial();
    final namaTagihanController = TextEditingController();
    final nominalController = TextEditingController();
    final tahunController = TextEditingController(text: DateTime.now().year.toString());
    String? selectedJenis;
    String? selectedBulan;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terbitkan Tagihan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: namaTagihanController, decoration: const InputDecoration(labelText: 'Nama Tagihan (Cth: Iuran RT)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Sifat Tagihan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.priority_high)),
                      value: selectedJenis,
                      items: const [DropdownMenuItem(value: 'wajib', child: Text('Wajib')), DropdownMenuItem(value: 'sukarela', child: Text('Tidak Wajib / Sukarela'))],
                      onChanged: (val) => setModalState(() => selectedJenis = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Bulan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month)),
                            value: selectedBulan,
                            items: _listBulan.map((b) => DropdownMenuItem<String>(value: b['id'].toString(), child: Text(b['nama']))).toList(),
                            onChanged: (val) => setModalState(() => selectedBulan = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 1, child: TextField(controller: tahunController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: isSubmitting ? null : () async {
                          if (namaTagihanController.text.isEmpty || selectedJenis == null || selectedBulan == null || tahunController.text.isEmpty || nominalController.text.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange));
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            final response = await http.post(
                              Uri.parse('http://10.0.2.2:3000/api/admin/buat-tagihan'),
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({'nama_tagihan': namaTagihanController.text, 'jenis': selectedJenis, 'bulan': selectedBulan, 'tahun': tahunController.text, 'nominal': nominalController.text}),
                            );
                            if (response.headers['content-type']?.contains('application/json') == true || response.body.startsWith('{')) {
                              final result = json.decode(response.body);
                              if (response.statusCode == 201 && mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
                                _refreshData();
                                Navigator.pop(modalContext);
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal membuat tagihan'), backgroundColor: Colors.red));
                              }
                            }
                          } catch (e) {
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Sebar ke Seluruh Warga'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFormEditTagihan(Map<String, dynamic> item) {
    final nominalController = TextEditingController(text: item['nominal'].toString());
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Tagihan: ${item['nama_kategori']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_getNamaBulan(item['bulan'].toString())} ${item['tahun']}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal Baru (Rp)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: isSubmitting ? null : () async {
                          if (nominalController.text.isEmpty) return;
                          setModalState(() => isSubmitting = true);
                          try {
                            final response = await http.put(
                              Uri.parse('http://10.0.2.2:3000/api/admin/edit-tagihan'),
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({'nama_kategori': item['nama_kategori'], 'jenis': item['jenis'], 'bulan': item['bulan'].toString(), 'tahun': item['tahun'].toString(), 'nominal_baru': nominalController.text}),
                            );
                            final result = json.decode(response.body);
                            if (response.statusCode == 200 && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
                              _refreshData();
                              Navigator.pop(modalContext);
                            }
                          } catch (e) {
                          } finally {
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
          },
        );
      },
    );
  }

  void _konfirmasiHapusTagihan(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Tagihan?'),
          content: Text('Yakin ingin menghapus tagihan ${item['nama_kategori']} untuk bulan ${_getNamaBulan(item['bulan'].toString())} ${item['tahun']} dari seluruh warga?\n\nTindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final response = await http.delete(
                    Uri.parse('http://10.0.2.2:3000/api/admin/hapus-tagihan'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'nama_kategori': item['nama_kategori'], 'jenis': item['jenis'], 'bulan': item['bulan'].toString(), 'tahun': item['tahun'].toString()}),
                  );
                  final result = json.decode(response.body);
                  if (response.statusCode == 200 && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
                    _refreshData();
                  }
                } catch (e) {}
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchRekap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('Gagal memuat data kas.'));
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(color: const Color(0xFF2196F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Uang Kas (Lunas)', style: TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(height: 8), Text('Rp ${double.parse(data['total_kas_masuk'].toString()).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))]))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [const Icon(Icons.check_circle, color: Colors.green, size: 32), const SizedBox(height: 8), const Text('Transaksi Lunas', style: TextStyle(color: Colors.grey)), Text('${data['total_transaksi_lunas']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])))),
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [const Icon(Icons.pending_actions, color: Colors.orange, size: 32), const SizedBox(height: 8), const Text('Belum Dibayar', style: TextStyle(color: Colors.grey)), Text('${data['total_transaksi_pending']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTamu() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchTamu(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada laporan tamu.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)), title: Text('${item['nama_tamu']} (${item['lama_menginap_hari']} Hari)', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Pelapor: ${item['nama']}\nPelat: ${item['pelat_kendaraan'] ?? '-'}'), isThreeLine: true));
          },
        );
      },
    );
  }

  Widget _buildFasum() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchFasum(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada laporan fasum.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.broken_image, color: Colors.white)), title: Text('${item['kategori']}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Pelapor: ${item['nama']}\nLokasi: ${item['deskripsi_lokasi']}'), isThreeLine: true));
          },
        );
      },
    );
  }

  Widget _buildDaftarTagihan() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchDaftarTagihan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada tagihan yang disebar.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: item['jenis'] == 'wajib' ? Colors.red : Colors.green, child: const Icon(Icons.receipt, color: Colors.white)),
                title: Text('${item['nama_kategori']} (${_getNamaBulan(item['bulan'].toString())} ${item['tahun']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Sifat: ${item['jenis'].toString().toUpperCase()}\nRp ${item['nominal']} • Disebar ke ${item['total_warga']} Warga'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormEditTagihan(item)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _konfirmasiHapusTagihan(item)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2196F3)),
              accountName: Text(widget.userData['nama'] ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: const Text('Administrator Smart RT'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blue),
              title: const Text('Dasbor Utama'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit_document, color: Colors.orange),
              title: const Text('Kelola Info & Jadwal'),
              subtitle: const Text('Edit atau hapus data'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminManageScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: Text('Dasbor Admin - ${widget.userData['nama']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _selectedIndex == 0 ? _buildDashboard() : _selectedIndex == 1 ? _buildTamu() : _selectedIndex == 2 ? _buildFasum() : _buildDaftarTagihan(),
          if (_isDialOpen) GestureDetector(onTap: _toggleDial, child: Container(color: Colors.black54)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isDialOpen) ...[
            FloatingActionButton.extended(heroTag: "btnTagihan", onPressed: _showFormTambahTagihan, label: const Text('Buat Tagihan'), icon: const Icon(Icons.receipt_long), backgroundColor: Colors.green, foregroundColor: Colors.white),
            const SizedBox(height: 10),
            FloatingActionButton.extended(heroTag: "btn1", onPressed: _showFormTambahJadwal, label: const Text('Buat Jadwal'), icon: const Icon(Icons.calendar_today), backgroundColor: Colors.purple, foregroundColor: Colors.white),
            const SizedBox(height: 10),
            FloatingActionButton.extended(heroTag: "btn2", onPressed: _showFormTambahInfo, label: const Text('Buat Pengumuman'), icon: const Icon(Icons.campaign), backgroundColor: Colors.orange, foregroundColor: Colors.white),
            const SizedBox(height: 10),
            FloatingActionButton.extended(heroTag: "btn3", onPressed: _showFormTambahWarga, label: const Text('Tambah Warga'), icon: const Icon(Icons.person_add), backgroundColor: Colors.blue, foregroundColor: Colors.white),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: "btnMain",
            onPressed: _toggleDial,
            backgroundColor: _isDialOpen ? Colors.red : const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            child: Icon(_isDialOpen ? Icons.close : Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Keuangan'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Tamu'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Fasum'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Tagihan'),
        ],
      ),
    );
  }
}