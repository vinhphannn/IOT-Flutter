import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Import đúng màn hình Setup cũ của vợ
import '../device_setup_screen.dart'; 

// --- MODEL (Giữ nguyên cấu trúc, nhưng device sẽ chứa BluetoothDevice thật) ---

class DeviceItem {

  final IconData icon;

  final String name;

  final Color color;

  final String macAddress;

  final String type;

  final BluetoothDevice? device; // Chứa đối tượng thiết bị thật



  DeviceItem({

    required this.name,

    required this.icon,

    required this.color,

    required this.macAddress,

    required this.type,

    this.device,

  });

}



class ScanNearbyScreen extends StatefulWidget {
  const ScanNearbyScreen({super.key});

  @override
  State<ScanNearbyScreen> createState() => _ScanNearbyScreenState();
}

class _ScanNearbyScreenState extends State<ScanNearbyScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  List<ScanResult> _scanResults = []; // Dùng thẳng ScanResult của thư viện, không tạo Model mới
  late AnimationController _rippleController;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _checkPermissionsAndStartScan();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _stopScan();
    super.dispose();
  }

  // 1. Xin quyền
  Future<void> _checkPermissionsAndStartScan() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cần quyền Bluetooth!")));
        return;
      }
    }
    _startScan();
  }

  // 2. Quét thiết bị
  void _startScan() async {
    setState(() { _isScanning = true; _scanResults.clear(); });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Lọc: Chỉ lấy tên có chữ "SmartMeter" hoặc "ESP32"
          _scanResults = results.where((r) {
            String name = r.device.platformName;
            return name.isNotEmpty && (name.contains("SmartMeter") || name.contains("ESP32"));
          }).toList();
          
          // Sắp xếp: Sóng mạnh lên đầu
          _scanResults.sort((a, b) => b.rssi.compareTo(a.rssi));
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) { print("Lỗi scan: $e"); }

    if (mounted) {
      setState(() { 
        _isScanning = false; 
        if (_scanResults.isNotEmpty) _rippleController.stop();
      });
    }
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    if (FlutterBluePlus.isScanningNow) FlutterBluePlus.stopScan();
  }

  // 3. Xử lý khi chọn thiết bị (GIỐNG HỆT LOGIC TRONG QR CODE)
  void _onDeviceSelected(BluetoothDevice device) async {
    _stopScan();
    
    // Hiện loading
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      // Thử kết nối
      await device.connect();
      
      if (!mounted) return;
      Navigator.pop(context); // Tắt loading

      // --- CHUYỂN TRANG THEO ĐÚNG FORMAT CŨ ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceSetupScreen(
            device: device,
            deviceType: "SmartDevice", // Vì quét radar không biết loại, đặt tạm tên chung
            macAddress: device.remoteId.str,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Tìm Thiết Bị Gần", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Radar Animation
          SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.wifi_tethering, size: 80, color: Colors.blue),
                if (_isScanning)
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (_, __) => Container(
                      width: 200 * _rippleController.value,
                      height: 200 * _rippleController.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.withOpacity(1 - _rippleController.value), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Text(_isScanning ? "Đang quét..." : "Tìm thấy ${_scanResults.length} thiết bị", 
               style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),

          // Danh sách thiết bị
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final r = _scanResults[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.developer_board, color: Colors.blue),
                    title: Text(r.device.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(r.device.remoteId.str, style: const TextStyle(color: Colors.grey)),
                    trailing: Text("${r.rssi} dBm", style: const TextStyle(color: Colors.green)),
                    onTap: () => _onDeviceSelected(r.device),
                  ),
                );
              },
            ),
          ),
          
          // Nút quét lại
          if (!_isScanning)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh),
                label: const Text("Quét Lại"),
              ),
            )
        ],
      ),
    );
  }
}