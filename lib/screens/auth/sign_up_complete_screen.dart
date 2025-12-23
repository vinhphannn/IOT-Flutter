import 'package:flutter/material.dart';
import '../../routes.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Nút X ở góc trái
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // Bấm X thì vào thẳng Home luôn
            Navigator.pushNamedAndRemoveUntil(
              context, 
              AppRoutes.home, 
              (route) => false
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(flex: 2), // Đẩy nội dung xuống giữa 

            // --- PHẦN HÌNH ẢNH (VẼ BẰNG CODE) ---
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Các chấm tròn trang trí (Confetti)
                  _buildDot(top: 20, right: 30, color: primaryColor, size: 8),
                  _buildDot(top: 40, left: 20, color: primaryColor.withOpacity(0.5), size: 6),
                  _buildDot(bottom: 30, right: 20, color: primaryColor.withOpacity(0.7), size: 6),
                  _buildDot(bottom: 20, left: 40, color: primaryColor, size: 5),
                  _buildDot(top: 10, left: 60, color: primaryColor.withOpacity(0.3), size: 4),
                  
                  // Vòng tròn lớn ở giữa
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor, // Màu xanh chủ đạo
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 50),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- TEXT ---
            const Text(
              "Well Done!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Congratulations! Your home is now a Smartify haven. Start exploring and managing your smart space with ease.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5, // Giãn dòng cho dễ đọc
              ),
            ),

            const Spacer(flex: 3), // Khoảng trống linh hoạt

            // --- NÚT GET STARTED ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Chuyển đến Home và xóa hết lịch sử back cũ
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    AppRoutes.home, 
                    (route) => false
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Hàm vẽ chấm tròn nhỏ (Helper)
  Widget _buildDot({double? top, double? bottom, double? left, double? right, required Color color, required double size}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}