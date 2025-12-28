import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../routes.dart'; // Chú ý đường dẫn import routes (lùi 3 cấp)

// Class Model (Giữ nguyên cấu trúc đã thống nhất)
class DeviceItem {
  final IconData icon;
  final String name;
  final Color color;
  final String macAddress;
  final String type;
  final dynamic device;
  DeviceItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.macAddress,
    required this.type,
    this.device,
  });
}

class NearbyScanTab extends StatefulWidget {
  const NearbyScanTab({super.key});

  @override
  State<NearbyScanTab> createState() => _NearbyScanTabState();
}

class _NearbyScanTabState extends State<NearbyScanTab> with TickerProviderStateMixin {
  // --- BIẾN LOGIC QUÉT ---
  bool _isScanning = true;
  List<DeviceItem> _foundDevices = [];
  late AnimationController _rippleController;

  // --- SỬA LỖI TẠI ĐÂY: Thêm macAddress và type cho các thiết bị mẫu ---
  final List<DeviceItem> _mockDevices = [
    DeviceItem(
      icon: Icons.lightbulb, 
      name: "Smart Bulb", 
      color: Colors.orange,
      macAddress: "00:11:22:33:44:55", // Thêm MAC giả lập
      type: "LIGHT",                   // Thêm Type
    ),
    DeviceItem(
      icon: Icons.router, 
      name: "Wifi Router", 
      color: Colors.blue,
      macAddress: "AA:BB:CC:DD:EE:FF",
      type: "ROUTER",
    ),
    DeviceItem(
      icon: Icons.speaker, 
      name: "Speaker", 
      color: Colors.red,
      macAddress: "12:34:56:78:90:AB",
      type: "SPEAKER",
    ),
    DeviceItem(
      icon: Icons.ac_unit, 
      name: "Air Cond", 
      color: Colors.cyan,
      macAddress: "FE:DC:BA:09:87:65",
      type: "AC",
    ),
    DeviceItem(
      icon: Icons.camera_indoor, 
      name: "Camera", 
      color: Colors.purple,
      macAddress: "D4:E9:F4:71:99:20", // MAC giống ESP cho vợ test
      type: "CAMERA",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startScanSimulation();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _startScanSimulation() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _foundDevices = _mockDevices;
          _rippleController.stop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView( 
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _isScanning
                ? "Looking for nearby devices..."
                : "Found ${_foundDevices.length} devices",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

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
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- RADAR ANIMATION ---
          SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(300),
                _buildRing(220),
                _buildRing(140),

                // Avatar ở giữa
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),

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
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                if (!_isScanning)
                  ...List.generate(_foundDevices.length, (index) {
                    final double angle = (2 * pi / _foundDevices.length) * index - (pi / 2);
                    const double radius = 110;

                    return Positioned(
                      left: 160 + radius * cos(angle) - 25,
                      top: 160 + radius * sin(angle) - 25,
                      child: _buildDeviceIcon(_foundDevices[index]),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 40),

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    "Connect to All Devices",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            Text("Scanning...", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () {},
            child: const Text("Can't find your devices? Learn more", style: TextStyle(color: Colors.grey)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

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

  Widget _buildDeviceIcon(DeviceItem device) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.connectDevice,
          arguments: device,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(device.icon, color: device.color),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              device.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}