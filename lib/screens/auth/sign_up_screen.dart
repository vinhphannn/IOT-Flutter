import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Cần import này cho hiệu ứng Blur
import '../../widgets/social_button.dart'; 
import '../../routes.dart';
import '../../services/auth_service.dart'; // <--- Import cái này

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isChecked = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

void _handleSignUp() async {
    // 1. VALIDATE (Giữ nguyên như cũ)
    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to Terms & Conditions first!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Email and Password."), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. LOGIC GỌI API
    setState(() {
      _isLoading = true; // Bật loading
    });

    // --- ĐOẠN NÀY LÀ CỐT LÕI MỚI ---
    AuthService authService = AuthService();
    bool success = await authService.register(
      _emailController.text, 
      _passController.text
    );
    // -------------------------------

    if (mounted) {
      setState(() {
        _isLoading = false; // Tắt loading
      });

      if (success) {
        // Đăng ký thành công -> Thông báo và chuyển sang trang Đăng nhập
        // (Lưu ý: Đăng ký xong thường phải đăng nhập lại để lấy Token)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công! Hãy đăng nhập."),
            backgroundColor: Colors.green,
          ),
        );
        
        // Chuyển hướng về trang Sign In thay vì Setup
        // Vì Setup cần Token, mà Đăng ký xong chưa có Token ngay.
        Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      } else {
        // Đăng ký thất bại (VD: Trùng email)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thất bại! Email có thể đã tồn tại."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // --- LỚP 1: GIAO DIỆN CHÍNH (Bên dưới) ---
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      "Join Smartify Today",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.person, color: primaryColor, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Join Smartify, Your Gateway to Smart Living.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                
                const SizedBox(height: 30),

                _buildLabel("Email"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                _buildLabel("Password"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _isChecked,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: "I agree to Smartify ",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          children: [
                            TextSpan(
                              text: "Terms & Conditions.",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                print("Tap Terms");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Sign in",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            Navigator.pushReplacementNamed(context, AppRoutes.signIn);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Center(child: Text("or", style: TextStyle(color: Colors.grey[400]))),
                const SizedBox(height: 30),

                SocialButton(
                  label: "Continue with Google",
                  iconPath: "assets/icons/google.png",
                  fallbackIcon: Icons.g_mobiledata,
                  onPressed: () {},
                ),
                const SizedBox(height: 15),
                
                SocialButton(
                  label: "Continue with Apple",
                  iconPath: "assets/icons/apple.png",
                  fallbackIcon: Icons.apple,
                  onPressed: () {},
                ),
                
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSignUp, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
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

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // --- LỚP 2: LOADING OVERLAY (Mặt nạ Blur Tối) ---
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                // SỬA Ở ĐÂY: Tăng opacity từ 0.5 lên 0.75 để nền tối hơn
                color: Colors.black.withOpacity(0.75), 
                child: Center(
                  child: Container(
                    width: size.width * 0.8,
                    padding: const EdgeInsets.symmetric(vertical: 70), 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          // SỬA Ở ĐÂY: Tăng độ đậm bóng đổ để hộp nổi bật hơn
                          color: Colors.black.withOpacity(0.2), 
                          blurRadius: 15, // Bóng lan rộng hơn
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Sign up...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        obscuringCharacter: '●',
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}