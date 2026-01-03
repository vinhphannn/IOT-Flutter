import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../routes.dart'; 

// --- MODEL DEVICE ITEM ---
// (Lớp này phải trùng khớp với cái mà routes.dart đang import)
class DeviceItem {
  final IconData icon;
  final String name;
  final Color color;
  final String macAddress;
  final String type;
  final BluetoothDevice? device; 

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
  // --- BIẾN LOGIC ---
  bool _isScanning = false;
  List<DeviceItem> _foundDevices = []; 
  late AnimationController _rippleController;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _checkPermissionsAndStartScan();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _stopScan();
    super.dispose();
  }

  // --- 1. LOGIC XIN QUYỀN ---
  Future<void> _checkPermissionsAndStartScan() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cần cấp quyền Bluetooth!")));
        return;
      }
    }
    _startRealScan();
  }

  // --- 2. LOGIC QUÉT THẬT ---
  void _startRealScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear(); 
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          final filtered = results.where((r) {
            String name = r.device.platformName;
            return name.isNotEmpty && 
                   (name.contains("SmartMeter") || name.contains("ESP32"));
          }).toList();

          filtered.sort((a, b) => b.rssi.compareTo(a.rssi));

          _foundDevices = filtered.map((r) {
            return DeviceItem(
              name: r.device.platformName,
              icon: Icons.developer_board, 
              color: Colors.blueAccent,    
              macAddress: r.device.remoteId.str,
              type: "ESP32",
              device: r.device, 
            );
          }).toList();
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Lỗi scan: $e");
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (_foundDevices.isNotEmpty) _rippleController.stop();
      });
    }
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    if (FlutterBluePlus.isScanningNow) FlutterBluePlus.stopScan();
  }

  // --- 3. LOGIC KẾT NỐI (ĐÃ SỬA) ---
  void _connectToDevice(DeviceItem item) {
    _stopScan();
    
    // 👇 SỬA Ở ĐÂY: Gửi nguyên object item đi, không bọc trong Map nữa
    Navigator.pushNamed(
      context,
      AppRoutes.connectDevice,
      arguments: item, // <--- Routes đang chờ DeviceItem, gửi đúng DeviceItem là khớp!
    );
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

          // Hướng dẫn
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
                  "Make sure device is in Pairing Mode",
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

                // --- VẼ THIẾT BỊ ---
                if (!_isScanning || _foundDevices.isNotEmpty)
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

          // Nút Connect
          if (!_isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_foundDevices.isNotEmpty) {
                      _connectToDevice(_foundDevices[0]);
                    } else {
                      _startRealScan();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  child: Text(
                    _foundDevices.isNotEmpty ? "Connect to Best Device" : "Scan Again",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            Text("Scanning...", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          TextButton(
            onPressed: _startRealScan,
            child: const Text("Can't find your devices? Scan Again", style: TextStyle(color: Colors.grey)),
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
      onTap: () => _connectToDevice(device), 
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
              border: Border.all(color: device.color, width: 2), 
            ),
            child: Icon(device.icon, color: device.color),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4)
            ),
            child: SizedBox(
              width: 70,
              child: Text(
                device.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}