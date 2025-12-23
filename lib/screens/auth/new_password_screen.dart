import 'package:flutter/material.dart';
import '../../routes.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  // Trạng thái ẩn/hiện mật khẩu
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // Controller
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Hàm xử lý lưu mật khẩu
  void _handleSavePassword() {
    String newPass = _newPassController.text;
    String confirmPass = _confirmPassController.text;

    // Validate cơ bản
    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) {
      // --- SỬA ĐOẠN NÀY ---
      // Chuyển sang trang Success
      Navigator.pushReplacementNamed(context, AppRoutes.resetPasswordSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header
            const Text(
              "Secure Your Account 🔒",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Almost there! Create a new password for your Smartify account to keep it secure. Remember to choose a strong and unique password.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            // Input New Password
            _buildLabel("New Password"),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _newPassController,
              isObscure: _obscureNewPass,
              onToggle: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),

            const SizedBox(height: 20),

            // Input Confirm Password
            _buildLabel("Confirm New Password"),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPassController,
              isObscure: _obscureConfirmPass,
              onToggle: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),

            const Spacer(), // Đẩy nút xuống đáy

            // Button Save
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handleSavePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Save New Password",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget Label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  // Widget Password Field (Tái sử dụng style cũ)
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        obscuringCharacter: '●', // Dấu chấm to
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: "●●●●●●●●", // Hint text dạng chấm
          hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 2),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[500],
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}