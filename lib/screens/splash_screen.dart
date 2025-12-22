import 'package:flutter/material.dart';
import '../routes.dart'; // Import file routes để điều hướng

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Bắt đầu đếm ngược 3 giây rồi chuyển trang
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      // Chuyển sang màn hình Onboarding
      // Dùng pushReplacementNamed để không cho user back lại Splash
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để căn chỉnh cho đẹp
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Sử dụng màu xanh chủ đạo từ Theme (đã cấu hình ở main.dart)
      backgroundColor: Theme.of(context).primaryColor, 
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Phần 1: Logo và Tên App (Căn giữa màn hình)
            Expanded(
              flex: 3, // Chiếm 3 phần không gian trên
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.25, // Logo rộng bằng 25% màn hình
                    height: size.width * 0.25,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  // Tên App
                  const Text(
                    'Smartify',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2, // Giãn chữ ra một chút cho sang
                    ),
                  ),
                ],
              ),
            ),

            // Phần 2: Loading (Nằm ở phía dưới)
            const Expanded(
              flex: 1, // Chiếm 1 phần không gian dưới
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3, // Độ dày vòng xoay
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}