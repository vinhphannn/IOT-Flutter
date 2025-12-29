import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../models/device_model.dart'; // Dùng Model Device thật
import '../control/device_control_screen.dart'; // Import trang điều khiển

class ConnectedSuccessScreen extends StatelessWidget {
  final Device device; // Nhận vào Device thật

  const ConnectedSuccessScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Icon Check Xanh
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4B6EF6), 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4B6EF6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 30),

            const Text(
              "Connected!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              "You have successfully connected to\n${device.name}.", // Hiện tên thiết bị
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
            ),

            const SizedBox(height: 50),

            // Hình ảnh thiết bị to ở giữa
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              // Dùng icon từ Model Device thật
              child: Icon(device.icon, size: 100, color: primaryColor),
            ),

            const Spacer(flex: 2),

            // 2 Nút bấm (Hàng ngang)
            Row(
              children: [
                // Nút Go to Homepage (Xám nhạt)
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Về trang chủ, xóa hết lịch sử quay lại
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFEFEF),
                        foregroundColor: const Color(0xFF4B6EF6), // Màu chữ
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text("Go to Homepage", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nút Control Device (Xanh đậm) -> VÀO ĐIỀU KHIỂN LUÔN
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Chuyển sang trang điều khiển thiết bị
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceControlScreen(device: device),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B6EF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                        shadowColor: const Color(0xFF4B6EF6).withOpacity(0.3),
                      ),
                      child: const Text("Control Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}