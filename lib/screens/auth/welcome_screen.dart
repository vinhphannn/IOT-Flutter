import 'package:flutter/material.dart';
import '../../widgets/social_button.dart';
import '../../routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng sạch sẽ
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Giãn đều trên dưới
            children: [
              
              // --- PHẦN 1: LOGO VÀ TEXT ---
              Column(
                children: [
                  SizedBox(height: size.height * 0.05), // Khoảng cách từ trên xuống
                  // Logo
                  Image.asset(
                    'assets/images/logo_mau.png', // Thay bằng logo màu của bạn
                    height: 80, 
                    fit: BoxFit.contain,
                    // Fallback nếu không thấy ảnh
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.wifi_tethering, 
                      size: 80, 
                      color: primaryColor
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Let's Get Started!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Let's dive in into your account",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),

              // --- PHẦN 2: CÁC NÚT MẠNG XÃ HỘI (Sử dụng Widget dùng chung) ---
              Column(
                children: [
                  // Google
                  SocialButton(
                    label: "Continue with Google",
                    iconPath: "assets/icons/google.png",
                    fallbackIcon: Icons.g_mobiledata,
                    onPressed: () => print("Google Welcome"),
                  ),
                  const SizedBox(height: 15),
                  
                  // Apple
                  SocialButton(
                    label: "Continue with Apple",
                    iconPath: "assets/icons/apple.png",
                    fallbackIcon: Icons.apple,
                    onPressed: () => print("Apple Welcome"),
                  ),
                  const SizedBox(height: 15),

                  // Facebook
                  SocialButton(
                    label: "Continue with Facebook",
                    iconPath: "assets/icons/facebook.png",
                    fallbackIcon: Icons.facebook,
                    onPressed: () => print("Facebook Welcome"),
                  ),
                  const SizedBox(height: 15),

                  // Twitter (X)
                  SocialButton(
                    label: "Continue with Twitter",
                    iconPath: "assets/icons/twitter.png",
                    fallbackIcon: Icons.flutter_dash,
                    onPressed: () => print("Twitter Welcome"),
                  ),
                ],
              ),

              // --- PHẦN 3: NÚT SIGN UP / SIGN IN ---
              Column(
                children: [
                  // Nút Sign Up (Màu đậm)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.pushNamed(context, AppRoutes.signUp);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),

                  // Nút Sign In (Màu nhạt - Giống nút Skip trang trước)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.signIn);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1), // Nền nhạt
                        foregroundColor: primaryColor, // Chữ đậm
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Sign in",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Footer Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Privacy Policy", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("·", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ),
                      Text("Terms of Service", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}