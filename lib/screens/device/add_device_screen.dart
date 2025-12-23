import 'dart:async';
import 'dart:math'; // Cần để tính sin/cos cho hình tròn
import 'package:flutter/material.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> with TickerProviderStateMixin {
  // --- 1. BIẾN UI ---
  int _selectedTab = 0; // 0: Nearby, 1: Manual

  // --- 2. BIẾN LOGIC QUÉT ---
  bool _isScanning = true;
  List<DeviceItem> _foundDevices = [];
  
  // Animation Controller cho vòng tròn lan tỏa
  late AnimationController _rippleController;

  // Danh sách thiết bị giả lập sẽ tìm thấy
  final List<DeviceItem> _mockDevices = [
    DeviceItem(icon: Icons.lightbulb, name: "Smart Bulb", color: Colors.orange),
    DeviceItem(icon: Icons.router, name: "Wifi Router", color: Colors.blue),
    DeviceItem(icon: Icons.speaker, name: "Speaker", color: Colors.red),
    DeviceItem(icon: Icons.ac_unit, name: "Air Cond", color: Colors.cyan),
    DeviceItem(icon: Icons.camera_indoor, name: "Camera", color: Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo Animation xoay vòng vòng nhẹ hoặc lan tỏa
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Chạy lặp lại vô tận

    // Bắt đầu giả lập quét
    _startScanSimulation();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  // --- LOGIC GIẢ LẬP ---
  void _startScanSimulation() {
    // Sau 3 giây thì hiện thiết bị
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _foundDevices = _mockDevices;
          _rippleController.stop(); // Dừng hiệu ứng lan tỏa
        });
      }
    });
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
          "Add Device",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          
          // 1. CUSTOM TABS (Nearby / Manual)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabItem("Nearby Devices", 0, primaryColor),
                _buildTabItem("Add Manual", 1, primaryColor),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 2. NỘI DUNG CHÍNH (SCANNER)
          if (_selectedTab == 0) 
            Expanded(child: _buildNearbyScanner(primaryColor))
          else 
            const Expanded(child: Center(child: Text("Manual Tab Content"))),
        ],
      ),
    );
  }

  // --- Widget Tab Item ---
  Widget _buildTabItem(String text, int index, Color primaryColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Scanner (Phần khó nhất nằm ở đây) ---
  Widget _buildNearbyScanner(Color primaryColor) {
    return Column(
      children: [
        // Header Text
        Text(
          _isScanning ? "Looking for nearby devices..." : "Found ${_foundDevices.length} devices",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        // Helper Badge (Wifi/Bluetooth)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Icon(Icons.bluetooth, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                "Turn on your Wifi & Bluetooth to connect",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            ],
          ),
        ),

        const Spacer(),

        // --- RADAR ANIMATION & DEVICES ---
        SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Các vòng tròn nền (Rings)
              _buildRing(300),
              _buildRing(220),
              _buildRing(140),

              // 2. Avatar ở giữa
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/user_avatar.png'), // Vợ nhớ thay ảnh user nhé
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)]
                ),
                // Fallback nếu chưa có ảnh
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),

              // 3. Hiệu ứng Ripple (Lan tỏa) khi đang scan
              if (_isScanning)
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return Container(
                      width: 300 * _rippleController.value,
                      height: 300 * _rippleController.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(1 - _rippleController.value),
                          width: 2
                        )
                      ),
                    );
                  },
                ),

              // 4. Các thiết bị tìm thấy (Sắp xếp theo hình tròn)
              if (!_isScanning)
                ...List.generate(_foundDevices.length, (index) {
                  // Toán lượng giác để chia đều các icon ra hình tròn
                  // Góc = (360 độ / số lượng) * thứ tự
                  final double angle = (2 * pi / _foundDevices.length) * index - (pi / 2); // -pi/2 để bắt đầu từ đỉnh 12h
                  final double radius = 110; // Bán kính vòng tròn thiết bị (nằm giữa vòng 2 và 3)
                  
                  return Positioned(
                    left: 160 + radius * cos(angle) - 25, // 160 là tâm (320/2), 25 là nửa size icon (50/2)
                    top: 160 + radius * sin(angle) - 25,
                    child: _buildDeviceIcon(_foundDevices[index]),
                  );
                })
            ],
          ),
        ),

        const Spacer(),

        // Button Connect
        if (!_isScanning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                child: const Text("Connect to All Devices", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        else
          // Text chờ
          Text("Scanning...", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),

        const SizedBox(height: 20),
        
        // Footer Link
        TextButton(
          onPressed: () {},
          child: const Text("Can't find your devices? Learn more", style: TextStyle(color: Colors.grey)),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Widget vẽ Vòng tròn nền ---
  Widget _buildRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1.5),
      ),
    );
  }

  // --- Widget vẽ Icon thiết bị ---
  Widget _buildDeviceIcon(DeviceItem device) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Icon(device.icon, color: device.color),
        ),
        // Có thể hiện tên bên dưới nếu thích
      ],
    );
  }
}

// Class Model đơn giản để chứa data
class DeviceItem {
  final IconData icon;
  final String name;
  final Color color;
  DeviceItem({required this.icon, required this.name, required this.color});
}