import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/device_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/energy_bar_chart.dart';
import '../../widgets/house_selector_dropdown.dart'; 

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  
  String _chartType = "week"; // Mặc định xem tuần
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _chartData = [];
  double _todayKwh = 0.0;
  double _monthKwh = 0.0;

  // Giá điện tham khảo (3.000 VNĐ / số)
  final double _kwhPrice = 3000.0;

  @override
  void initState() {
    super.initState();
    // Đảm bảo load xong danh sách thiết bị thì mới load report
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    final devices = context.read<DeviceProvider>().devices;
    
    // 1. Lấy dữ liệu biểu đồ
    final chartResult = await _reportService.getHouseEnergyChart(devices, _chartType);
    
    // 2. Lấy tổng quan (Hôm nay & Tháng này)
    final overviewResult = await _reportService.getOverview(devices);

    if (mounted) {
      setState(() {
        _chartData = chartResult;
        _todayKwh = overviewResult['today']!;
        _monthKwh = overviewResult['month']!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: HouseSelectorDropdown()),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
                ],
              ),
              const SizedBox(height: 20),

              // 2. OVERVIEW CARDS (Tiền điện)
              Row(
                children: [
                  _buildOverviewCard(
                    title: "Hôm nay",
                    kwh: _todayKwh,
                    cost: _todayKwh * _kwhPrice,
                    icon: Icons.flash_on,
                    color: Colors.orange,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(width: 16),
                  _buildOverviewCard(
                    title: "30 ngày qua",
                    kwh: _monthKwh,
                    cost: _monthKwh * _kwhPrice,
                    icon: Icons.calendar_month,
                    color: Colors.blueAccent,
                    currencyFormat: currencyFormat,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. CHART SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Thống kê", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        // Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _chartType,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: "week", child: Text("7 ngày qua")),
                                DropdownMenuItem(value: "month", child: Text("30 ngày qua")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _chartType = val);
                                  _fetchData(); // Load lại chart
                                }
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // BIỂU ĐỒ
                    SizedBox(
                      height: 200,
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator()) 
                          : EnergyBarChart(data: _chartData),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. DEVICE LIST (Danh sách tiêu thụ)
              const Text("Thiết bị tiêu thụ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deviceProvider.devices.length,
                itemBuilder: (context, index) {
                  final device = deviceProvider.devices[index];
                  // Lấy trường totalKwh từ Model Device (được cập nhật qua Socket)
                  final cost = device.totalKwh * _kwhPrice;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Icon(device.icon, color: Colors.grey[600]), 
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("${device.totalKwh.toStringAsFixed(2)} kWh", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(device.roomName, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                  Text(currencyFormat.format(cost), style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title, required double kwh, required double cost,
    required IconData icon, required Color color, required NumberFormat currencyFormat
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text("${kwh.toStringAsFixed(1)} kWh", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(currencyFormat.format(cost), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}