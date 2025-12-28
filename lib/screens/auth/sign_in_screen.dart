import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/social_button.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm cái này
import '../../services/house_service.dart'; // Thêm cái này
import '../../models/house_model.dart'; // Thêm cái này (nếu cần dùng model House)

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Trạng thái
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- HÀM XỬ LÝ ĐĂNG NHẬP (NÃO BỘ) ---
  // --- HÀM XỬ LÝ ĐĂNG NHẬP (LOGIC CHUẨN) ---
  void _handleSignIn() async {
    // 1. Validate (Giữ nguyên)
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Email and Password."), backgroundColor: Colors.red));
      return;
    }

    // 2. Bật Loading
    setState(() => _isLoading = true);

    // 3. GỌI API LOGIN
    AuthService authService = AuthService();
    
    // Giả sử hàm login trong AuthService chỉ trả về Token hoặc true/false
    // Hoặc trả về Map nhưng ta chỉ quan tâm nó thành công hay không
    Map<String, dynamic>? loginResult = await authService.login(
      _emailController.text,
      _passController.text,
    );

    if (loginResult != null) {
      // --- 4. LOGIN THÀNH CÔNG -> GỌI TIẾP API HOUSE ĐỂ CHECK SETUP ---
      try {
        // Lưu token xong rồi, giờ kiểm tra xem user này có nhà chưa
        HouseService houseService = HouseService();
        final houses = await houseService.fetchMyHouses();
        
        final prefs = await SharedPreferences.getInstance();

        if (houses.isNotEmpty) {
          // A. ĐÃ CÓ NHÀ -> Vào Home
          await prefs.setBool('is_setup_completed', true);
          
          // Lưu ID nhà mặc định luôn
          await prefs.setInt('currentHouseId', houses[0].id);

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome back! 👋"), backgroundColor: Colors.green));
          }
        } else {
          // B. CHƯA CÓ NHÀ -> Vào Setup
          await prefs.setBool('is_setup_completed', false);
          
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Let's set up your home! 🏠"), backgroundColor: Colors.blue));
          }
        }
      } catch (e) {
        // Lỗi khi gọi API House (Mạng lag, Server lỗi...)
        debugPrint("Error checking setup status: $e");
        // Fallback: Cho vào Home luôn hoặc báo lỗi tùy em, ở đây anh cho vào Setup cho an toàn
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
      }
    } else {
      // 5. Login Thất bại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed! Incorrect email or password."), backgroundColor: Colors.red));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // --- LỚP 1: GIAO DIỆN CHÍNH ---
        Scaffold(
          backgroundColor: Colors.white,
          // --- TRONG SignInScreen.dart ---
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // Kiểm tra nếu có thể quay lại thì pop, không thì về Welcome
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // Trường hợp này dùng khi vừa đăng xuất xong, ngăn xếp trống
                  Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
                }
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Tiêu đề
                Row(
                  children: [
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("👋", style: TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Your Smart Home, Your Rules.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                const SizedBox(height: 30),

                // Email Input
                _buildLabel("Email"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                // Password Input
                _buildLabel("Password"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Row: Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Remember me",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.forgotPassword);
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Center(
                  child: Text("or", style: TextStyle(color: Colors.grey[400])),
                ),
                const SizedBox(height: 30),

                // Social Buttons
                SocialButton(
                  label: "Continue with Google",
                  iconPath: "assets/icons/google.png",
                  fallbackIcon: Icons.g_mobiledata,
                  onPressed: () async {
                    // Logic Google Login cũng cần sửa tương tự để check setup
                    // Tạm thời vợ cứ để Login thường chạy ngon trước đã nhé
                  },
                ),
                const SizedBox(height: 15),
                SocialButton(
                  label: "Continue with Apple",
                  iconPath: "assets/icons/apple.png",
                  fallbackIcon: Icons.apple,
                  onPressed: () {},
                ),
                const SizedBox(height: 15),
                SocialButton(
                  label: "Continue with Facebook",
                  iconPath: "assets/icons/facebook.png",
                  fallbackIcon: Icons.facebook,
                  onPressed: () {},
                ),

                const SizedBox(height: 40),

                // Nút Sign In
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // --- LỚP 2: LOADING OVERLAY ---
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
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
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
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
                          "Sign in...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            decoration: TextDecoration.none,
                          ),
                        ),
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

  // --- Helper Widgets ---
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
