import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Bắt buộc phải có
import '../../../models/device_model.dart';
import '../../../providers/device_provider.dart'; // Import Kho tổng
import '../../device/log/device_log_screen.dart';
import '../../device/DeviceEnergyChartScreen.dart';

class SocketControlWidget extends StatelessWidget {
  final int deviceId; // Nhận ID thay vì Device object

  const SocketControlWidget({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    
    final primaryColor = Theme.of(context).primaryColor;
    print("🔍 [DEBUG] SocketControlWidget nhận được deviceId: $deviceId");

    // --- LẮNG NGHE TOÀN CỤC ---
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        // 1. Tìm thiết bị trong kho dựa vào ID
        // Nếu không tìm thấy (do lỗi gì đó) thì trả về thiết bị rỗng để App không bị Crash
        final device = provider.devices.firstWhere(
          (d) => d.id == deviceId,
          orElse: () => Device(id: 0, name: 'Error', macAddress: '', type: '', isOn: false, roomName: ''),
        );

        // Lấy dữ liệu từ Model (đã được Provider cập nhật liên tục)
        final isOnline = device.isOnline;
        final currentWatt = device.power;
        final currentAmpere = device.current;
        final todayKwh = device.totalKwh;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Column(
              children: [
                // --- LOGIC UI: KHI OFFLINE THÌ KHÓA & MỜ ĐI ---
                AbsorbPointer(
                  absorbing: !isOnline,
                  child: Opacity(
                    opacity: isOnline ? 1.0 : 0.5,
                    child: Column(
                      children: [
                        // NÚT BẤM (GỌI HÀM TRONG PROVIDER)
                        _buildCentralButton(context, device, provider),

                        // BẢNG CHỈ SỐ
                        _buildPowerStats(currentAmpere, currentWatt),
                      ],
                    ),
                  ),
                ),

                // THÔNG TIN PHỤ (Vẫn cho xem khi Offline)
                _buildExtraInfo(context, device, todayKwh),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget con: Nút bấm trung tâm
  Widget _buildCentralButton(BuildContext context, Device device, DeviceProvider provider) {
    final primaryColor = Theme.of(context).primaryColor;
    final isOnline = device.isOnline;

    return GestureDetector(
      // GỌI HÀM TOGGLE CỦA PROVIDER
      onTap: () {
        if (isOnline) {
          provider.toggleDevice(device.id);
        }
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isOnline)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: device.isOn ? 200 : 180,
                  height: device.isOn ? 200 : 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.isOn ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                    border: Border.all(color: device.isOn ? primaryColor.withOpacity(0.2) : Colors.transparent, width: 2),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? (device.isOn ? primaryColor : Colors.grey[200]) : Colors.grey[300],
                  boxShadow: (isOnline && device.isOn) ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))] : [],
                ),
                child: Icon(
                  isOnline ? Icons.power_settings_new : Icons.wifi_off,
                  size: 50,
                  color: isOnline ? (device.isOn ? Colors.white : Colors.grey[500]) : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isOnline)
            const Text("MẤT KẾT NỐI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red))
          else
            Text(device.isOn ? "TRẠNG THÁI: ĐANG BẬT" : "TRẠNG THÁI: ĐANG TẮT", style: TextStyle(color: device.isOn ? primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPowerStats(double ampere, double watt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Dòng điện", "${ampere.toStringAsFixed(2)}A", Icons.bolt_rounded),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _buildStatItem("Công suất", "${watt.toStringAsFixed(1)}W", Icons.speed_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(children: [Icon(icon, color: Colors.grey[400], size: 24), const SizedBox(height: 12), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
  }

  Widget _buildExtraInfo(BuildContext context, Device device, double kwh) {
    return Column(
      children: [
        _buildInfoCard(Icons.eco_outlined, "Điện năng hôm nay", "${kwh.toStringAsFixed(3)} kWh", Colors.green, () {
        // --- CHUYỂN SANG TRANG BIỂU ĐỒ MỚI ---
        Navigator.push(
            context, 
            MaterialPageRoute(
                builder: (context) => DeviceEnergyChartScreen(deviceId: device.id)
            )
        );
    }),
        const SizedBox(height: 12),
        _buildInfoCard(Icons.history_rounded, "Lịch sử hoạt động", "Xem chi tiết", Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceLogScreen(deviceId: device.id)));
        }),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(24)),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.grey))])), const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)]),
      ),
    );
  }
}