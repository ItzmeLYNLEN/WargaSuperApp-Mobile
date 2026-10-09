import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> infoList = [];
  List<dynamic> jadwalList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      final resInfo = await http.get(Uri.parse('http://10.0.2.2:3000/api/informasi'));
      final resJadwal = await http.get(Uri.parse('http://10.0.2.2:3000/api/jadwal'));
      
      if (resInfo.statusCode == 200 && resJadwal.statusCode == 200) {
        setState(() {
          infoList = json.decode(resInfo.body)['data'];
          jadwalList = json.decode(resJadwal.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= EDIT PENGUMUMAN =================
  void _showEditInfoForm(Map<String, dynamic> item) {
    final tipeController = TextEditingController(text: item['tipe']);
    final judulController = TextEditingController(text: item['judul']);
    final kontenController = TextEditingController(text: item['konten']);
    PlatformFile? selectedFile;
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
                  const Text('Edit Pengumuman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: tipeController, decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category))),
                  const SizedBox(height: 12),
                  TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 12),
                  TextField(controller: kontenController, maxLines: 3, decoration: const InputDecoration(labelText: 'Konten', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'xlsx', 'xls']);
                          if (result != null) setModalState(() => selectedFile = result.files.first);
                        },
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Ganti File'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile != null ? selectedFile!.name : (item['file_lampiran'] != null ? 'File lama tersimpan' : 'Tidak ada file'),
                          style: TextStyle(color: selectedFile != null ? Colors.blue : Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      onPressed: isSubmitting ? null : () async {
                        setModalState(() => isSubmitting = true);
                        try {
                          var request = http.MultipartRequest('PUT', Uri.parse('http://10.0.2.2:3000/api/admin/informasi/${item['id']}'));
                          request.fields['tipe'] = tipeController.text;
                          request.fields['judul'] = judulController.text;
                          request.fields['konten'] = kontenController.text;

                          if (selectedFile != null && selectedFile!.path != null) {
                            request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path!));
                          }
                          var res = await http.Response.fromStream(await request.send());
                          if (res.statusCode == 200 && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Berhasil diupdate!'), backgroundColor: Colors.green));
                            _loadAllData();
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

  // ================= EDIT JADWAL =================
  void _showEditJadwalForm(Map<String, dynamic> item) {
    final judulController = TextEditingController(text: item['judul_kegiatan']);
    final jenisController = TextEditingController(text: item['jenis_kegiatan']);
    DateTime? selectedDate = DateTime.tryParse(item['tanggal_kegiatan'].toString().split('T')[0]);
    PlatformFile? selectedFile;
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
                  const Text('Edit Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Nama Kegiatan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event))),
                  const SizedBox(height: 12),
                  TextField(controller: jenisController, decoration: const InputDecoration(labelText: 'Jenis Kegiatan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.list))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(child: Text(selectedDate == null ? 'Pilih Tanggal' : 'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                            if (picked != null) setModalState(() => selectedDate = picked);
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
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'xlsx', 'xls']);
                          if (result != null) setModalState(() => selectedFile = result.files.first);
                        },
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Ganti File'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile != null ? selectedFile!.name : (item['file_lampiran'] != null ? 'File lama tersimpan' : 'Tidak ada file'),
                          style: TextStyle(color: selectedFile != null ? Colors.purple : Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                      onPressed: isSubmitting ? null : () async {
                        if (selectedDate == null) return;
                        setModalState(() => isSubmitting = true);
                        try {
                          String formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                          var request = http.MultipartRequest('PUT', Uri.parse('http://10.0.2.2:3000/api/admin/jadwal/${item['id']}'));
                          request.fields['judul_kegiatan'] = judulController.text;
                          request.fields['jenis_kegiatan'] = jenisController.text;
                          request.fields['tanggal_kegiatan'] = formattedDate;

                          if (selectedFile != null && selectedFile!.path != null) {
                            request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path!));
                          }
                          var res = await http.Response.fromStream(await request.send());
                          if (res.statusCode == 200 && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Berhasil diupdate!'), backgroundColor: Colors.green));
                            _loadAllData();
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

  // ================= KONFIRMASI HAPUS =================
  void _confirmDelete(String type, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus $type ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              String url = type == 'pengumuman' ? 'http://10.0.2.2:3000/api/admin/informasi/$id' : 'http://10.0.2.2:3000/api/admin/jadwal/$id';
              final res = await http.delete(Uri.parse(url));
              if (res.statusCode == 200) {
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('$type dihapus!'), backgroundColor: Colors.green));
                _loadAllData();
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
        title: const Text('Manajemen Info & Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Pengumuman'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Jadwal Kegiatan'),
          ],
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: PENGUMUMAN
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: infoList.length,
                itemBuilder: (context, index) {
                  final item = infoList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(item['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(6)),
                            child: Text(item['tipe'], style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(item['konten'], maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (item['file_lampiran'] != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Row(children: [Icon(Icons.attachment, size: 16, color: Colors.blue), SizedBox(width: 4), Text('Ada Lampiran', style: TextStyle(color: Colors.blue, fontSize: 12))]),
                            )
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditInfoForm(item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete('pengumuman', item['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // TAB 2: JADWAL
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jadwalList.length,
                itemBuilder: (context, index) {
                  final item = jadwalList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(item['judul_kegiatan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('📅 ${item['tanggal_kegiatan'].toString().split('T')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                          const SizedBox(height: 4),
                          Text('Jenis: ${item['jenis_kegiatan']}'),
                          if (item['file_lampiran'] != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Row(children: [Icon(Icons.attachment, size: 16, color: Colors.purple), SizedBox(width: 4), Text('Ada Lampiran', style: TextStyle(color: Colors.purple, fontSize: 12))]),
                            )
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditJadwalForm(item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete('jadwal', item['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }
}