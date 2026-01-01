import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';
import 'dart:convert';

class DeviceEnergyChartScreen extends StatefulWidget {
  final int deviceId;
  const DeviceEnergyChartScreen({super.key, required this.deviceId});

  @override
  State<DeviceEnergyChartScreen> createState() => _DeviceEnergyChartScreenState();
}

class _DeviceEnergyChartScreenState extends State<DeviceEnergyChartScreen> {
  bool _isLoading = true;
  String _chartType = "week"; // "week" hoặc "month"
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  // --- GỌI API ---
  Future<void> _fetchChartData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/devices/${widget.deviceId}/energy/chart?type=$_chartType');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _chartData = data.map((e) => {
            "date": DateTime.parse(e['date'].toString()),
            "total": double.parse(e['total'].toString())
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy chart: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tiêu thụ điện năng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- TAB CHUYỂN ĐỔI TUẦN/THÁNG ---
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildTab("Tuần này", "week"),
                  _buildTab("Tháng này", "month"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- BIỂU ĐỒ ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chartData.isEmpty
                      ? const Center(child: Text("Chưa có dữ liệu"))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY() * 1.2, // Tăng trần thêm 20% cho đẹp
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black87,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String date = DateFormat('dd/MM').format(_chartData[groupIndex]['date']);
                                  return BarTooltipItem(
                                    '$date\n',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    children: [TextSpan(text: '${rod.toY.toStringAsFixed(2)} kWh', style: TextStyle(color: primaryColor))],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < _chartData.length) {
                                      DateTime date = _chartData[index]['date'];
                                      // Nếu xem tuần thì hiện Thứ (T2, T3...), Tháng thì hiện ngày (01, 05...)
                                      String text = _chartType == 'week' 
                                          ? DateFormat('E', 'vi').format(date) // Cần intl hỗ trợ tiếng Việt hoặc dùng logic switch case
                                          : DateFormat('dd').format(date);
                                      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: const TextStyle(fontSize: 10)));
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Ẩn trục trái
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: _chartData.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value['total'],
                                    color: primaryColor,
                                    width: _chartType == 'week' ? 20 : 8,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: _getMaxY() * 1.2, color: Colors.grey[100]),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
            
            const SizedBox(height: 20),
            
            // --- TỔNG KẾT ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.blue, size: 30),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tổng tiêu thụ (${_chartType == 'week' ? 'Tuần' : 'Tháng'})", style: TextStyle(color: Colors.grey[600])),
                      Text(
                        "${_getTotal().toStringAsFixed(2)} kWh",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget Tab chọn
  Widget _buildTab(String title, String type) {
    bool isSelected = _chartType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chartType = type);
          _fetchChartData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_chartData.isEmpty) return 10;
    return _chartData.map((e) => e['total'] as double).reduce((a, b) => a > b ? a : b);
  }

  double _getTotal() {
    if (_chartData.isEmpty) return 0;
    return _chartData.fold(0.0, (sum, item) => sum + item['total']);
  }
}