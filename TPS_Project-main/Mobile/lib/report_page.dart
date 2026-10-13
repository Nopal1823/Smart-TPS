import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class ReportPage extends StatefulWidget {
  final int spotId;
  final String spotName;

  const ReportPage({
    super.key,
    required this.spotId,
    required this.spotName,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _descController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 80,
      );

      // --- PERBAIKAN 1: Cek mounted setelah await ---
      if (!mounted) return;
      // ----------------------------------------------

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // --- PERBAIKAN 2: Cek mounted sebelum pakai context di catch ---
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar: $e")),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap sertakan foto bukti!")),
      );
      return;
    }

    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi deskripsi laporan!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/api/reports/');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Token $token';
    request.fields['spot'] = widget.spotId.toString();
    request.fields['description'] = _descController.text;

    var pic = await http.MultipartFile.fromPath('image', _imageFile!.path);
    request.files.add(pic);

    try {
      // Proses Async (Menunggu kirim data)
      var response = await request.send();

      // --- PERBAIKAN UTAMA ADA DI SINI ---
      // Cek apakah halaman masih aktif setelah menunggu proses di atas?
      if (!mounted) return;
      // -----------------------------------

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil dikirim!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return; // Cek juga di block catch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error koneksi: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Ambil dari Galeri'),
                  onTap: () {
                    Navigator.of(context).pop(); // Tutup modal dulu
                    _pickImage(ImageSource.gallery);
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(context).pop(); // Tutup modal dulu
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Laporan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Laporkan Masalah di:\n${widget.spotName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _showPickerOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("Ketuk untuk tambah foto"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Masalah',
                hintText: 'Contoh: Bau sangat menyengat, sampah menumpuk...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.send),
              label: const Text("Kirim Laporan"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}