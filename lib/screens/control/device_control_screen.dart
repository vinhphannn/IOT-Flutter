import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import 'bodies/light_control_body.dart'; // Import file ruột đèn

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({super.key, required this.device});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late bool _isDeviceOn;

  @override
  void initState() {
    super.initState();
    _isDeviceOn = widget.device.isOn;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Control Device",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. THÔNG TIN THIẾT BỊ (HEADER DÙNG CHUNG)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Icon thiết bị
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: Icon(widget.device.icon, size: 30, color: Colors.black54),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(widget.device.room, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                
                // Nút Bật/Tắt to
                Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: _isDeviceOn,
                    activeColor: Colors.white,
                    activeTrackColor: primaryColor,
                    onChanged: (val) => setState(() => _isDeviceOn = val),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 30, thickness: 1, color: Color(0xFFF5F5F5)),

          // 2. PHẦN RUỘT (THAY ĐỔI THEO LOẠI THIẾT BỊ)
          Expanded(
            child: _buildBodyContent(),
          ),

          // 3. NÚT SCHEDULE (DÙNG CHUNG Ở DƯỚI CÙNG)
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Mở trang hẹn giờ (Làm sau)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFEFEF), // Màu xám xanh nhạt như thiết kế
                  foregroundColor: const Color(0xFF4B6EF6), // Chữ màu xanh
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Schedule Automatic ON/OFF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm quyết định hiển thị ruột nào
  Widget _buildBodyContent() {
    switch (widget.device.type) {
      case 'Light':
        return const LightControlBody(); // Gọi file ruột đèn
      
      case 'AC':
        // return const ACControlBody(); // Sau này làm thêm file này
        return const Center(child: Text("AC Control Coming Soon"));
        
      default:
        return const Center(child: Text("Generic Control"));
    }
  }
}