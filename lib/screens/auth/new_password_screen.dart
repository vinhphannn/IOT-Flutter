import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart'; // <--- 1. Import cái này để đăng nhập

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  String? _email;
  String? _otp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _email = args['email'];
      _otp = args['otp'];
    }
  }

  // --- HÀM GỌI API ĐỔI PASS + AUTO LOGIN ---
  void _handleSavePassword() async {
    String newPass = _newPassController.text;
    String confirmPass = _confirmPassController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red));
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpToSend = _otp?.toString().trim();

      // 1. GỌI API ĐẶT LẠI MẬT KHẨU
      final response = await ApiClient.post('/auth/reset-password', {
        "email": _email,
        "otp": otpToSend, 
        "newPassword": newPass
      }, withToken: false);

      if (response.statusCode == 200) {
        // --- 2. LOGIC MỚI: TỰ ĐỘNG ĐĂNG NHẬP LUÔN ---
        print("✅ Đổi pass thành công! Đang tự động đăng nhập...");
        
        AuthService authService = AuthService();
        // Gọi hàm login để lấy Token và lưu vào SharedPreferences
        var loginResult = await authService.login(_email!, newPass);

        if (loginResult != null && mounted) {
           print("✅ Auto Login thành công! Đã lưu Token.");
           // 3. Chuyển sang màn hình Success (Lúc này đã có Token trong máy rồi)
           Navigator.pushReplacementNamed(context, AppRoutes.resetPasswordSuccess);
        } else {
           // Nếu xui xẻo login lỗi thì về màn hình đăng nhập thủ công
           if (mounted) {
             Navigator.pushReplacementNamed(context, AppRoutes.signIn);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed! Please login."), backgroundColor: Colors.green));
           }
        }
        // ---------------------------------------------
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP or Expired!"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ... (Giữ nguyên phần UI của vợ không cần sửa gì cả) ...
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Secure Your Account 🔒", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            Text("Create a new password for your Smartify account.", style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 30),

            _buildLabel("New Password"),
            const SizedBox(height: 8),
            _buildPasswordField(controller: _newPassController, isObscure: _obscureNewPass, onToggle: () => setState(() => _obscureNewPass = !_obscureNewPass)),

            const SizedBox(height: 20),

            _buildLabel("Confirm New Password"),
            const SizedBox(height: 8),
            _buildPasswordField(controller: _confirmPassController, isObscure: _obscureConfirmPass, onToggle: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass)),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSavePassword,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 2),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save New Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
  
  Widget _buildPasswordField({required TextEditingController controller, required bool isObscure, required VoidCallback onToggle}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        obscuringCharacter: '●',
        decoration: InputDecoration(
          hintText: "●●●●●●●●",
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onToggle),
        ),
      ),
    );
  }
}