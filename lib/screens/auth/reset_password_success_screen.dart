import 'package:flutter/material.dart';
import '../../routes.dart';

class ResetPasswordSuccessScreen extends StatelessWidget {
  const ResetPasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(flex: 2), 

            // --- PHẦN HÌNH ẢNH MINH HỌA (VẼ BẰNG CODE) ---
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Vòng tròn nền xanh lớn
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B6EF6), // Màu xanh tím giống thiết kế
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4B6EF6).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                  ),

                  // 2. Hình chiếc điện thoại
                  Container(
                    width: 60,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 4), // Viền máy
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Loa thoại (vạch nhỏ trên đầu)
                        Container(
                          width: 20, height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Avatar người dùng màu xanh
                        Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4B6EF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- TEXT ---
            const Text(
              "You're All Set!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your password has been successfully changed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const Spacer(flex: 3), 

            // --- NÚT GO TO HOMEPAGE ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Chuyển thẳng về Home và xóa hết lịch sử cũ
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    AppRoutes.home, 
                    (route) => false
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B6EF6), // Màu xanh tím
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF4B6EF6).withOpacity(0.4),
                ),
                child: const Text(
                  "Go to Homepage",
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
}