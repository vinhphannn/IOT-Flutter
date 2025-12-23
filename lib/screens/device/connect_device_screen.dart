import 'dart:async';
import 'package:flutter/material.dart';
import 'add_device_screen.dart'; // Import để lấy class DeviceItem
import '../../routes.dart';

class ConnectDeviceScreen extends StatefulWidget {
  final DeviceItem device; 

  const ConnectDeviceScreen({super.key, required this.device});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  double _progress = 0.0; 
  Timer? _timer;
  
  // Thêm biến để kiểm soát trạng thái
  bool _hasStarted = false; // Đã bấm nút Connect chưa?
  bool _isConnected = false; // Đã chạy xong 100% chưa?

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Hàm bắt đầu chạy giả lập khi bấm nút
// Trong _ConnectDeviceScreenState

  void _handleConnect() {
    setState(() {
      _hasStarted = true; 
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          if (_progress < 1.0) {
            _progress += 0.01; 
          } else {
            // --- KHI XONG (100%) ---
            _progress = 1.0;
            _isConnected = true; 
            timer.cancel();
            
            // --- TỰ ĐỘNG CHUYỂN TRANG LUÔN ---
            // Đợi 1 xíu (300ms) cho người dùng kịp nhìn thấy số 100% rồi mới chuyển
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.pushReplacementNamed( // Dùng replacement để không quay lại trang loading được
                  context, 
                  AppRoutes.connectedSuccess, 
                  arguments: widget.device // Truyền thiết bị sang trang Success
                );
              }
            });
          }
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final int percentage = (_progress * 100).toInt();
    final size = MediaQuery.of(context).size;

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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              // 1. Header Tab giả
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Nearby Devices", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Expanded(
                      child: Text("Add Manual", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.04),

              const Text(
                "Connect to device",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Badge Wifi/Bluetooth
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconBadge(Icons.wifi, primaryColor),
                  const SizedBox(width: 8),
                  _buildIconBadge(Icons.bluetooth, primaryColor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text("Turn on your Wifi & Bluetooth to connect", 
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              // Tên thiết bị
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.device.name, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
                ],
              ),

              SizedBox(height: size.height * 0.05),

              // 3. VÒNG TRÒN TIẾN TRÌNH HOẶC ẢNH TĨNH
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    // Chỉ hiện vòng tròn loading khi ĐÃ BẤM nút Connect
                    if (_hasStarted)
                      CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeCap: StrokeCap.round, 
                      ),
                    
                    // Hình ảnh thiết bị (Luôn hiện)
                    Padding(
                      padding: const EdgeInsets.all(35.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          // Nếu chưa bắt đầu thì không cần bóng đổ xanh, chỉ bóng mờ
                          boxShadow: [
                            BoxShadow(
                              color: _hasStarted ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1), 
                              blurRadius: 20, 
                              spreadRadius: 5
                            )
                          ]
                        ),
                        child: Icon(
                          widget.device.icon, 
                          size: 100, // Icon to hơn xíu cho đẹp
                          color: _isConnected ? primaryColor : (_hasStarted ? primaryColor : Colors.grey[600])
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // 4. TRẠNG THÁI & NÚT BẤM (Thay đổi theo biến _hasStarted và _isConnected)
              
              if (!_hasStarted) ...[
                // --- TRẠNG THÁI 1: CHƯA KẾT NỐI ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleConnect, // Bấm để bắt đầu chạy
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      "Connect", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
                ),
              ] else if (!_isConnected) ...[
                // --- TRẠNG THÁI 2: ĐANG CHẠY % ---
                const Text(
                  "Connecting...",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  "$percentage%",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                // Khi đang chạy thì ẩn nút đi (hoặc hiện nút Cancel nếu muốn)
                const SizedBox(height: 55), 
              ] else ...[
                // --- TRẠNG THÁI 3: HOÀN TẤT ---
                const Text(
                  "Connected Successfully!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  
                ),
              ],

              const SizedBox(height: 20),
              
              // Text Link
              if (!_isConnected)
                TextButton(
                  onPressed: () {},
                  child: const Text("Can't connect with your devices? Learn more", style: TextStyle(color: Colors.blue, fontSize: 12)),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}