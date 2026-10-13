import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Untuk akses baseUrl
import 'sensor_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> _spots = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _username = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchSpots();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _role = 'Warga';
    });
  }

  Future<void> _fetchSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/api/spots/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _spots = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sesi habis. Silakan login ulang.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error koneksi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  // --- APP BAR TRANSPARAN (AGAR MIRIP WEB) ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, // Transparan agar kena background hijau
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: false,
      automaticallyImplyLeading: false, // Hilangkan tombol back default
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 10),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF539050), size: 32),
            const SizedBox(width: 8),
            Text(
              'Smart TPS',
              style: GoogleFonts.poppins(
                color: const Color(0xFF539050),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24, top: 10),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _username,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _role,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Tombol Logout Kotak Putih
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white, // Latar putih pada tombol
                    border: Border.all(color: const Color(0xFF539050), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: Color(0xFF539050), size: 18),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // --- KARTU TPS ---
  Widget _buildSpotCard(dynamic spot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Sudut lebih bulat
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF539050).withValues(alpha: 0.08), // Bayangan kehijauan
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SensorDetailPage(
                  spotId: spot['id'],
                  spotName: spot['nama_lokasi'],
                ),
              ),
            );
          },
          child: Stack(
            children: [
              // Hiasan Visual: Gelombang Sinyal Transparan di Pojok Kanan
              Positioned(
                bottom: -15,
                right: -10,
                child: Icon(
                  Icons.sensors,
                  size: 110,
                  color: const Color(0xFF539050).withValues(alpha: 0.08),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Atas: Badge Aktif & ID Sensor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAF0DF), // Hijau Badge
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Aktif",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF388E3C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Text(
                              spot['sensor_id'] ?? "ESP32_${spot['id']}",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Judul TPS
                    Text(
                      spot['nama_lokasi'] ?? 'Lokasi Tanpa Nama',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Alamat
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            spot['alamat'] ?? 'Alamat tidak tersedia',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- BACKGROUND GRADIENT (KUNCI AGAR MIRIP WEB) ---
      extendBodyBehindAppBar: true, // Header tembus ke atas
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Gradasi Hijau Muda seperti di Login & Web
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF5CB), // Hijau Lime Terang
              Color(0xFFF2F9E5), // Putih Kehijauan
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(), // Panggil Header Transparan

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _fetchSpots, child: const Text("Coba Lagi"))
                      ],
                    ))
                    : RefreshIndicator(
                  onRefresh: _fetchSpots,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Judul Halaman
                        Text(
                          "Monitoring Kualitas Udara",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF539050),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Pantau kondisi sensor TPA secara realtime dan akurat.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // List Kartu TPS
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _spots.length,
                          itemBuilder: (context, index) {
                            return _buildSpotCard(_spots[index]);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}