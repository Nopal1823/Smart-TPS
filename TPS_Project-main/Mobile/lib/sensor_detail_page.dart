import 'dart:async'; // Timer ada di sini
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Pastikan baseUrl ada di sini
import 'report_page.dart';

class SensorDetailPage extends StatefulWidget {
  final int spotId;
  final String spotName;

  const SensorDetailPage({super.key, required this.spotId, required this.spotName});

  @override
  State<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends State<SensorDetailPage> {
  List<dynamic> _historyData = [];
  Map<String, dynamic>? _latestData;
  bool _isLoading = true;
  String _errorMessage = '';

  // Variabel Timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1. Panggil data pertama kali (tampilkan loading)
    _fetchSensorLog();

    // 2. Jalankan Timer setiap 5 detik (update di background tanpa loading)
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchSensorLog(isBackground: true);
    });
  }

  @override
  void dispose() {
    // 3. Matikan timer saat keluar halaman agar HP tidak panas
    _timer?.cancel();
    super.dispose();
  }

  // --- FUNGSI FETCH DATA (HANYA BOLEH ADA SATU) ---
  Future<void> _fetchSensorLog({bool isBackground = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // MENGGUNAKAN LIMIT=20 AGAR CEPAT
    final url = Uri.parse('$baseUrl/api/sensor-logs/?spot_id=${widget.spotId}&limit=20');

    try {
      // Logic: Kalau bukan background process (artinya refresh manual atau awal), tampilkan loading
      if (!isBackground) {
        setState(() => _isLoading = true);
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);

        // Cek 'mounted' agar tidak error jika user sudah pindah halaman saat data baru sampai
        if (mounted) {
          setState(() {
            if (dataList.isNotEmpty) {
              _latestData = dataList[0];
              // Ambil 10 data untuk grafik & balik urutannya
              _historyData = dataList.take(10).toList().reversed.toList();
            } else {
              _latestData = null;
              _historyData = [];
            }
            _isLoading = false;
            _errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() { _errorMessage = 'Gagal: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = 'Error: $e'; _isLoading = false; });
      }
    }
  }

  // --- LOGIKA STATUS WARNA & ICON ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aman': return const Color(0xFF00C853);
      case 'Sedang': return const Color(0xFFFFAB00);
      case 'Bahaya': return const Color(0xFFD50000);
      default: return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Aman': return "Udara Bersih/Normal";
      case 'Sedang': return "Waspada (Bau Ringan)";
      case 'Bahaya': return "BAHAYA (Bau Menyengat!)";
      default: return "Status tidak diketahui";
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Aman': return Icons.verified_user;
      case 'Sedang': return Icons.warning_amber_rounded;
      case 'Bahaya': return Icons.dangerous;
      default: return Icons.help_outline;
    }
  }

  // --- WIDGET CHART ---
  Widget _buildChart() {
    final List<dynamic> chartData = _historyData.isEmpty
        ? List.generate(10, (index) => {
      'mq2': 0, 'mq3': 0, 'mq4': 0,
      'mq8': 0, 'mq9': 0, 'mq135': 0
    })
        : _historyData;

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tren Kualitas Udara",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              const Icon(Icons.show_chart, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLine(chartData, 'mq2', Colors.blueAccent),
                  _buildLine(chartData, 'mq3', Colors.amber),
                  _buildLine(chartData, 'mq4', Colors.green),
                  _buildLine(chartData, 'mq8', Colors.redAccent),
                  _buildLine(chartData, 'mq9', Colors.blueGrey),
                  _buildLine(chartData, 'mq135', const Color(0xFF6610f2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _legendItem(Colors.blueAccent, "MQ2"),
              _legendItem(Colors.amber, "MQ3"),
              _legendItem(Colors.green, "MQ4"),
              _legendItem(Colors.redAccent, "MQ8"),
              _legendItem(Colors.blueGrey, "MQ9"),
              _legendItem(const Color(0xFF6610f2), "MQ135"),
            ],
          )
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<dynamic> data, String key, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value[key] ?? 0).toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _sensorCard(String label, dynamic value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            ],
          ),
          const Spacer(),
          Text(
            "$value",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String serverStatus = _latestData?['ai_status'] ?? 'Aman';
    final Color statusColor = _getStatusColor(serverStatus);
    final String statusMessage = _getStatusMessage(serverStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.spotName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Jika user tekan manual, kita mau lihat loading spinner
              _fetchSensorLog(isBackground: false);
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () {
                _fetchSensorLog(isBackground: false);
              },
              child: const Text("Coba Lagi"),
            )
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha: 0.8)
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(_getStatusIcon(serverStatus), color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    serverStatus.toUpperCase(),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    statusMessage,
                    style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "AI Cluster: ${_latestData?['ai_cluster'] ?? '-'}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),

            // CHART
            Transform.translate(
              offset: const Offset(0, -30),
              child: _buildChart(),
            ),

            // GRID SENSORS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _sensorCard("MQ-2 (Asap)", _latestData?['mq2'] ?? 0, Icons.whatshot, Colors.blue),
                  _sensorCard("MQ-3 (Alkohol)", _latestData?['mq3'] ?? 0, Icons.science, Colors.amber),
                  _sensorCard("MQ-4 (Metana)", _latestData?['mq4'] ?? 0, Icons.grass, Colors.green),
                  _sensorCard("MQ-8 (Hidrogen)", _latestData?['mq8'] ?? 0, Icons.bolt, Colors.redAccent),
                  _sensorCard("MQ-9 (CO)", _latestData?['mq9'] ?? 0, Icons.cloud, Colors.blueGrey),
                  _sensorCard("MQ-135 (Amonia)", _latestData?['mq135'] ?? 0, Icons.air, const Color(0xFF6610f2)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON LAPOR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text("Lapor Bau Busuk",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(
                      "Cium bau menyengat? Segera laporkan agar petugas dapat menindaklanjuti.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportPage(spotId: widget.spotId, spotName: widget.spotName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text("Kirim Laporan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}