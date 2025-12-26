import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes.dart';
// Import màn hình tiếp theo
import 'wifi_selection_screen.dart'; 

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with SingleTickerProviderStateMixin {
  // --- BIẾN QUẢN LÝ ---
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlashOn = false;
  bool _isProcessing = false; // Cờ để chặn quét nhiều lần liên tục

  // UUID Service của ESP32 (Phải KHỚP 100% với code C++ trên ESP32)
  final String _targetServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  @override
  void initState() {
    super.initState();
    // 1. Hiệu ứng dòng quét lên xuống
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // 2. Check quyền Camera
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================
  // PHẦN 1: LOGIC QUYỀN (PERMISSION)
  // ==========================================

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) {
        // OK
      } else {
        if (mounted) _showPermissionDialog("Camera", "App cần quyền Camera để quét mã QR.");
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog("Camera", "Quyền Camera bị tắt. Vui lòng bật lại trong Cài đặt.");
    }
  }

  void _showPermissionDialog(String permissionName, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Cần cấp quyền $permissionName"),
        content: Text(reason),
        actions: [
          TextButton(
            child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Thoát màn hình
            },
          ),
          TextButton(
            child: const Text("Mở Cài Đặt", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHẦN 2: LOGIC XỬ LÝ (SCAN & CONNECT)
  // ==========================================

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Chặn nếu đang xử lý

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        _controller.stop(); // Tạm dừng Camera
        debugPrint('🔍 QR Found: ${barcode.rawValue}');
        
        await _processQrData(barcode.rawValue!);
        break; 
      }
    }
  }

  Future<void> _processQrData(String qrData) async {
    try {
      // 1. Parse JSON
      // Mẫu JSON: {"mac":"...", "type":"LIGHT", "ble":"SmartHome_ESP32"}
      final Map<String, dynamic> data = jsonDecode(qrData);
      // Lấy các thông tin cần thiết
      String deviceType = data['type'] ?? "DEVICE";
      String macAddress = data['mac'] ?? "";

      // 2. Xin quyền Bluetooth
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Android < 12 cần location
      ].request();

      bool isDenied = statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
      if (isDenied) {
         if (mounted) {
            _showPermissionDialog("Bluetooth", "Cần quyền Bluetooth để kết nối thiết bị.");
            setState(() => _isProcessing = false);
         }
         return;
      }

      // 3. Hiện Dialog Loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Đang tìm thiết bị..."),
                  Text("(Vui lòng để điện thoại gần thiết bị)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );

      // 4. Quét Bluetooth (Logic XỊN: Tìm theo UUID)
      BluetoothDevice? targetDevice;
      
      // Bắt đầu scan (Lọc theo UUID Service của ESP32)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(_targetServiceUuid)], // <--- CHÌA KHÓA QUAN TRỌNG
      );
      
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // Vì đã lọc bằng UUID nên cứ thấy là lụm thôi
          targetDevice = r.device;
          FlutterBluePlus.stopScan(); 
          break;
        }
      });

      // Chờ tối đa 6 giây
      await Future.delayed(const Duration(seconds: 6));
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      subscription.cancel();

      // 5. Kết nối
      if (targetDevice != null) {
        debugPrint("⚡ Found Device: ${targetDevice!.remoteId}");
        
        // Kết nối thử để đảm bảo sống
        await targetDevice!.connect();
        
        if (mounted) {
          Navigator.pop(context); // Đóng loading
          
          // Chuyển sang màn hình chọn Wifi (File tiếp theo vợ sẽ làm)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WifiSelectionScreen(
                device: targetDevice!, 
                deviceType: deviceType,
                macAddress: macAddress,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
           Navigator.pop(context); // Đóng loading
           _showError("Không tìm thấy thiết bị!\nHãy chắc chắn thiết bị đang ở chế độ cài đặt (Đèn xanh dương).");
        }
      }

    } catch (e) {
      debugPrint("❌ Lỗi: $e");
      if (mounted) {
         if (Navigator.canPop(context)) Navigator.pop(context); // Đóng loading nếu có
         _showError("Mã QR không hợp lệ hoặc lỗi Bluetooth.");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 3))
    );
    // Restart camera sau 3 giây để user đọc lỗi xong
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.start();
        setState(() => _isProcessing = false);
      }
    });
  }

  // ==========================================
  // PHẦN 3: GIAO DIỆN UI (ĐÃ CHUẨN ĐẸP)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Lớp phủ mờ (Overlay)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: scanAreaSize,
                    width: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Khung quét & Hiệu ứng
          Center(
            child: SizedBox(
              height: scanAreaSize,
              width: scanAreaSize,
              child: Stack(
                children: [
                  // Các góc vuông
                  _buildCorner(Align(alignment: Alignment.topLeft, child: _cornerWidget(0))),
                  _buildCorner(Align(alignment: Alignment.topRight, child: _cornerWidget(90))),
                  _buildCorner(Align(alignment: Alignment.bottomLeft, child: _cornerWidget(270))),
                  _buildCorner(Align(alignment: Alignment.bottomRight, child: _cornerWidget(180))),

                  // Thanh quét chạy
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value * (scanAreaSize - 20),
                        left: 0, right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            boxShadow: [
                              BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Controls UI
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text("Scan Device QR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48), // Placeholder để cân giữa
                    ],
                  ),
                ),
                const Spacer(),
                const Text("Align QR code within the frame", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                
                // Nút nhập tay (Tùy chọn)
                GestureDetector(
                  onTap: () { /* Logic nhập tay sau này */ },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text("Enter setup code manually", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),

                // Flash Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: IconButton(
                    icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Widget child) => SizedBox(height: 40, width: 40, child: child);

  Widget _cornerWidget(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns ~/ 90,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white, width: 4),
            left: BorderSide(color: Colors.white, width: 4),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
        ),
      ),
    );
  }
}