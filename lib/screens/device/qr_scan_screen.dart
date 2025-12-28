import 'dart:convert';
import 'dart:async';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart'; // <--- 1. IMPORT CÁI NÀY

import '../../routes.dart';
import 'device_setup_screen.dart'; 

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
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ... (Giữ nguyên phần logic Camera Permission như cũ) ...
  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return;
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) return;
    }
    if (mounted) {
       _showPermissionDialog("Camera", "Vui lòng cấp quyền Camera để quét mã QR.");
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
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
          ),
          TextButton(
            child: const Text("Mở Cài Đặt", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHẦN MỚI: CHỌN ẢNH TỪ THƯ VIỆN
  // ==========================================
 // ==========================================
  // SỬA HÀM CHỌN ẢNH TỪ THƯ VIỆN
  // ==========================================
  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return; // Người dùng không chọn ảnh

      setState(() => _isProcessing = true);
      
      // --- SỬA ĐOẠN NÀY ---
      // analyzeImage trả về BarcodeCapture? (dữ liệu) chứ không phải bool
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        // Nếu tìm thấy QR, gọi hàm xử lý _onDetect có sẵn
        _onDetect(capture);
      } else {
        // Nếu capture là null hoặc danh sách rỗng
        setState(() => _isProcessing = false);
        if (mounted) _showError("Không tìm thấy mã QR trong ảnh này!");
      }
      // ---------------------
      
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
      setState(() => _isProcessing = false);
      if(mounted) _showError("Lỗi khi đọc ảnh.");
    }
  }

  // ==========================================
  // LOGIC XỬ LÝ QR (GIỮ NGUYÊN)
  // ==========================================

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        _controller.stop(); // Dừng camera ngay khi bắt được
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

      // Kiểm tra quyền Bluetooth
      bool isGranted = false;
      if (Platform.isIOS) {
        var status = await Permission.bluetooth.status;
        if (status.isGranted) isGranted = true;
        else isGranted = (await Permission.bluetooth.request()).isGranted;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
        isGranted = !statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
      }

      if (!isGranted) {
         if (mounted) {
            _showPermissionDialog("Bluetooth", "Cần quyền Bluetooth để tìm thiết bị.");
            setState(() => _isProcessing = false);
         }
         return;
      }

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
                children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Đang tìm thiết bị...")],
              ),
            ),
          ),
        ),
      );

      // Quét Bluetooth
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
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
      subscription.cancel();

      if (targetDevice != null) {
        await targetDevice!.connect();
        if (mounted) {
          Navigator.pop(context); // Đóng Loading
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceSetupScreen(
                device: targetDevice!, 
                deviceType: deviceType,
                macAddress: macAddress,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
           Navigator.pop(context); // Đóng dialog loading
           _showError("Không tìm thấy thiết bị! Hãy chắc chắn thiết bị đang ở chế độ chờ kết nối.");
        }
      }

    } catch (e) {
      debugPrint("❌ Lỗi: $e");
      if (mounted) {
         // Đóng dialog loading nếu đang mở
         if (Navigator.canPop(context)) Navigator.pop(context); 
         _showError("Mã QR không hợp lệ hoặc lỗi kết nối.");
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

  @override
  Widget build(BuildContext context) {
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
                      // Nút giả để cân đối tiêu đề
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("Align QR code within the frame", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                
                // --- THANH CÔNG CỤ DƯỚI CÙNG (ĐÈN & ẢNH) ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nút Chọn Ảnh
                      _buildControlButton(
                        icon: Icons.image, 
                        label: "Gallery",
                        onTap: _pickImageFromGallery,
                      ),
                      
                      const SizedBox(width: 40), // Khoảng cách

                      // Nút Đèn Flash
                      _buildControlButton(
                        icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        label: "Flash",
                        onTap: () {
                          _controller.toggleTorch();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con để vẽ nút tròn đẹp
  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
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