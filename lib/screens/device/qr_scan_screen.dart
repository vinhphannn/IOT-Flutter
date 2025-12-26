import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../routes.dart';
// Import màn hình tiếp theo (Chọn Wifi) - Đảm bảo đường dẫn đúng
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
  bool _isProcessing = false; // Biến cờ để tránh quét liên tục

  @override
  void initState() {
    super.initState();
    // 1. Setup Hiệu ứng dòng quét
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // 2. Check quyền Camera ngay khi mở màn hình
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
        // Đã cấp quyền -> OK
      } else {
        if (mounted) _showPermissionDialog("Camera", "App cần quyền Camera để quét mã QR thiết bị.");
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog("Camera", "Bạn đã tắt quyền Camera. Vui lòng vào Cài đặt để bật lại.");
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
              Navigator.pop(ctx); // Đóng Dialog
              Navigator.pop(context); // Thoát màn hình Scan
            },
          ),
          TextButton(
            child: const Text("Mở Cài Đặt", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Mở trang cài đặt điện thoại
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHẦN 2: LOGIC QUÉT VÀ KẾT NỐI
  // ==========================================

  // Hàm gọi khi Camera bắt được mã QR
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Nếu đang xử lý thì chặn lại

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        _controller.stop(); // Tạm dừng Camera
        debugPrint('🔍 QR Found: ${barcode.rawValue}');
        
        // Bắt đầu quy trình kết nối
        await _processQrData(barcode.rawValue!);
        break; 
      }
    }
  }

  Future<void> _processQrData(String qrData) async {
    try {
      // A. Parse JSON từ QR
      // Mẫu JSON: {"id":"ESP_01", "name":"SmartHome_ESP32", "pop":"123"}
      final Map<String, dynamic> data = jsonDecode(qrData);
      String deviceName = data['name']; // Tên Bluetooth cần tìm
      String deviceId = data['id'];
      
      // B. Xin quyền Bluetooth & Vị trí (Quan trọng cho Android 12+)
      // Note: Android < 12 cần Location để scan BLE
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool isDenied = statuses.values.any((s) => s.isDenied);
      bool isPermanent = statuses.values.any((s) => s.isPermanentlyDenied);

      if (isDenied || isPermanent) {
         if (mounted) {
            _showPermissionDialog(
              "Bluetooth & Vị trí", 
              "Để kết nối với thiết bị thông minh, App cần quyền Bluetooth và Vị trí."
            );
            setState(() => _isProcessing = false); // Reset để quét lại
         }
         return;
      }

      // C. Hiện Dialog Loading
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
                  Text("Đang tìm và kết nối thiết bị..."),
                ],
              ),
            ),
          ),
        ),
      );

      // D. Quét thiết bị BLE
      BluetoothDevice? targetDevice;
      
      // Bắt đầu scan (timeout 10 giây)
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // Ưu tiên lấy tên từ gói quảng cáo (Advertisement Data)
          String foundName = r.advertisementData.localName.isNotEmpty 
              ? r.advertisementData.localName 
              : r.device.platformName;
          
          // Debug xem tìm thấy những gì
          // debugPrint("Found BLE: $foundName");

          if (foundName == deviceName) {
            targetDevice = r.device;
            FlutterBluePlus.stopScan(); // Tìm thấy rồi thì dừng scan ngay
            break;
          }
        }
      });

      // Đợi tối đa 5 giây để scan
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      subscription.cancel();

      // E. Kết nối
      if (targetDevice != null) {
        debugPrint("⚡ Connecting to: ${targetDevice!.platformName}");
        await targetDevice!.connect();
        
        if (mounted) {
          Navigator.pop(context); // Đóng dialog loading
          
          // Chuyển sang màn hình chọn Wifi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WifiSelectionScreen(
                device: targetDevice!, 
                deviceId: deviceId
              ),
            ),
          );
        }
      } else {
        if (mounted) {
           Navigator.pop(context); // Đóng dialog loading
           _showError("Không tìm thấy thiết bị '$deviceName'.\nHãy chắc chắn thiết bị đang bật và ở gần.");
        }
      }

    } catch (e) {
      debugPrint("❌ Lỗi QR/BLE: $e");
      if (mounted) {
         // Đóng dialog loading nếu còn mở
         if (Navigator.canPop(context)) Navigator.pop(context); 
         _showError("Mã QR không hợp lệ hoặc lỗi kết nối!");
      }
    } finally {
      // Nếu thất bại mà vẫn ở màn hình này, cho phép quét lại
      if (mounted && _isProcessing) {
        // Chỉ reset cờ xử lý nếu không chuyển trang
        // (Logic chuyển trang đã xử lý ở trên)
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
    // Restart camera sau 2 giây để user đọc lỗi xong quét lại
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.start();
        setState(() => _isProcessing = false);
      }
    });
  }

  // ==========================================
  // PHẦN 3: GIAO DIỆN (UI)
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

          // 2. Lớp phủ mờ xung quanh (Overlay)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54, 
              BlendMode.srcOut, 
            ),
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

                  // Thanh quét chạy lên xuống
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value * (scanAreaSize - 20),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent, 
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
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

          // 4. Các nút bấm và Text
          SafeArea(
            child: Column(
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Scan Device",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Text hướng dẫn
                const Text(
                  "Can't scan the QR code?",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Nút nhập tay
                GestureDetector(
                  onTap: () {
                     // Logic nhập tay (Optional - Nếu vợ muốn làm thì thêm dialog nhập ID)
                     Navigator.pop(context); 
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), 
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "Enter setup code manually",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Các nút điều khiển dưới cùng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Nút Flash
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off, 
                          color: Colors.white, size: 28
                        ),
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                      ),

                      // Nút chụp ảnh (Trang trí)
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, 
                          ),
                        ),
                      ),

                      // Nút Thư viện ảnh (Trang trí - hoặc thêm tính năng chọn ảnh sau)
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget vẽ góc vuông ---
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