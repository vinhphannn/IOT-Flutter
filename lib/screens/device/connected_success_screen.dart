import 'package:flutter/material.dart';
import '../../routes.dart';
import 'add_device_screen.dart'; // Import để lấy class DeviceItem
import 'tabs/nearby_scan_tab.dart';
class ConnectedSuccessScreen extends StatelessWidget {
  final DeviceItem device;

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
                color: const Color(0xFF4B6EF6), // Xanh tím đẹp
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
              "You have connected to ${device.name}.", // Hiện tên thiết bị
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 50),

            // Hình ảnh thiết bị to ở giữa
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(device.icon, size: 120, color: device.color),
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
                // Nút Control Device (Xanh đậm)
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Tạm thời cũng về Home hoặc chuyển sang trang điều khiển (làm sau)
                        print("Navigate to Control Device");
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