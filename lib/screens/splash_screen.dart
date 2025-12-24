import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../routes.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  // --- PHẦN NÀY LÀ NÃO BỘ MỚI (Logic xịn) ---
  _navigateToNextScreen() async {
    // 1. Giữ nguyên thời gian chờ 3s theo thiết kế của vợ
    await Future.delayed(const Duration(seconds: 3));

    // 2. Lấy dữ liệu từ bộ nhớ máy
    final prefs = await SharedPreferences.getInstance();
    
    // Check 1: Đã xem Onboarding chưa?
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    
    // Check 2: Đã đăng nhập chưa? (SỬA KEY THÀNH 'jwt_token' CHO KHỚP AUTH SERVICE)
    final String? token = prefs.getString('jwt_token'); 
    final bool isLoggedIn = token != null && token.isNotEmpty;

    // Check 3: Đã Setup nhà chưa? (MỚI THÊM)
    final bool isSetupCompleted = prefs.getBool('is_setup_completed') ?? false;

    if (!mounted) return;

    // 3. Điều hướng thông minh (Updated Logic)
    if (isLoggedIn) {
      // --- TRƯỜNG HỢP 1: ĐÃ ĐĂNG NHẬP ---
      if (isSetupCompleted) {
        // A. Đã có nhà -> Vào thẳng Home
        print("User cũ: Vào thẳng Home");
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // B. Chưa có nhà -> Vào Setup
        print("User mới: Vào Setup");
        Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
      }
    } else {
      // --- TRƯỜNG HỢP 2: CHƯA ĐĂNG NHẬP ---
      if (seenOnboarding) {
        // C. Khách quen (đã xem intro) -> Vào Welcome/Login Options
        Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
      } else {
        // D. Khách mới tinh -> Vào Onboarding
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    }
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    // --- PHẦN GIAO DIỆN GIỮ NGUYÊN 100% THEO THIẾT KẾ ---
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Sử dụng màu xanh chủ đạo từ Theme
      backgroundColor: Theme.of(context).primaryColor, 
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Phần 1: Logo và Tên App (Căn giữa màn hình)
            Expanded(
              flex: 3, 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.25, 
                    height: size.width * 0.25,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.smart_toy, size: 60, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tên App
                  const Text(
                    'Smartify',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2, 
                    ),
                  ),
                ],
              ),
            ),

            // Phần 2: Loading (Nằm ở phía dưới)
            const Expanded(
              flex: 1, 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3, 
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