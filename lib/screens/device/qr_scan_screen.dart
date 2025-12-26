import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Import để check Platform
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes.dart';
import 'wifi_selection_screen.dart'; 

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  final String _targetServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // Kiểm tra quyền Camera ngay khi mở (nhưng check khéo léo)
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================
  // PHẦN 1: LOGIC QUYỀN CAMERA (TỐI ƯU UX)
  // ==========================================

  Future<void> _checkCameraPermission() async {
    // 1. Kiểm tra trạng thái hiện tại trước
    var status = await Permission.camera.status;

    // 2. Nếu đã cho phép rồi -> RETURN LUÔN, không làm phiền user
    if (status.isGranted) return;

    // 3. Nếu chưa cho phép -> Mới xin
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) return; // Xin được thì thôi
    }

    // 4. Nếu bị từ chối vĩnh viễn hoặc từ chối -> Mới hiện Dialog của mình
    if (mounted) {
       _showPermissionDialog("Camera", "Vui lòng cấp quyền Camera trong Cài đặt để quét mã QR.");
    }
  }

  void _showPermissionDialog(String permissionName, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Cần quyền $permissionName"),
        content: Text(reason),
        actions: [
          TextButton(
            child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); 
            },
          ),
          TextButton(
            child: const Text("Mở Cài Đặt", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Mở cài đặt hệ thống
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHẦN 2: LOGIC QUÉT & BLUETOOTH (TỐI ƯU UX)
  // ==========================================

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        _controller.stop();
        debugPrint('🔍 QR Found: ${barcode.rawValue}');
        
        await _processQrData(barcode.rawValue!);
        break; 
      }
    }
  }

  Future<void> _processQrData(String qrData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      String deviceType = data['type'] ?? "DEVICE";
      String macAddress = data['mac'] ?? "";

      // --- LOGIC KIỂM TRA QUYỀN BLUETOOTH (TỐI ƯU) ---
      bool isGranted = false;

      if (Platform.isIOS) {
        // A. Kiểm tra trước xem đã có quyền chưa
        var status = await Permission.bluetooth.status;
        
        if (status.isGranted) {
          isGranted = true; // Có rồi thì đi tiếp luôn
        } else {
          // Chưa có thì mới xin
          var requestStatus = await Permission.bluetooth.request();
          isGranted = requestStatus.isGranted;
        }
      } else {
        // Android (Logic cũ)
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
        isGranted = !statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
      }

      // Nếu sau khi xin mà vẫn không có quyền -> Hiện Dialog hướng dẫn
      if (!isGranted) {
         if (mounted) {
            _showPermissionDialog(
              "Bluetooth", 
              "Ứng dụng cần quyền Bluetooth để tìm thiết bị. Vui lòng bật trong Cài đặt."
            );
            setState(() => _isProcessing = false);
         }
         return;
      }

      // --- NẾU CÓ QUYỀN THÌ CHẠY TIẾP (KHÔNG HIỆN POPUP NỮA) ---

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
                ],
              ),
            ),
          ),
        ),
      );

      // Quét Bluetooth tìm thiết bị theo UUID
      BluetoothDevice? targetDevice;
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(_targetServiceUuid)],
      );
      
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          targetDevice = r.device;
          FlutterBluePlus.stopScan(); 
          break;
        }
      });

      await Future.delayed(const Duration(seconds: 6));
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      subscription.cancel();

      if (targetDevice != null) {
        await targetDevice!.connect();
        if (mounted) {
          Navigator.pop(context); // Đóng Loading
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
           Navigator.pop(context); // Đóng Loading
           _showError("Không tìm thấy thiết bị!");
        }
      }

    } catch (e) {
      debugPrint("❌ Lỗi: $e");
      if (mounted) {
         if (Navigator.canPop(context)) Navigator.pop(context);
         _showError("Mã QR lỗi hoặc Bluetooth chưa bật.");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 3))
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.start();
        setState(() => _isProcessing = false);
      }
    });
  }

  // ... (Phần Giao diện UI và các Widget con giữ nguyên như cũ) ...
  @override
  Widget build(BuildContext context) {
    // ... Copy phần UI từ file cũ sang đây ...
    // (Chồng chỉ gửi phần logic để file đỡ dài, phần UI vợ giữ nguyên nhé)
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                Center(child: Container(height: scanAreaSize, width: scanAreaSize, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              height: scanAreaSize, width: scanAreaSize,
              child: Stack(
                children: [
                  _buildCorner(Align(alignment: Alignment.topLeft, child: _cornerWidget(0))),
                  _buildCorner(Align(alignment: Alignment.topRight, child: _cornerWidget(90))),
                  _buildCorner(Align(alignment: Alignment.bottomLeft, child: _cornerWidget(270))),
                  _buildCorner(Align(alignment: Alignment.bottomRight, child: _cornerWidget(180))),
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
                            boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                      const Text("Scan Device QR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("Align QR code within the frame", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
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
          border: Border(top: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
        ),
      ),
    );
  }
}