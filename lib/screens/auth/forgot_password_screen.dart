import 'package:flutter/material.dart';
import '../../routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

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
            // Tiêu đề
            const Text(
              "Forgot Your Password? 🔑",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Mô tả
            Text(
              "We've got you covered. Enter your registered email to reset your password. We will send an OTP code to your email for the next steps.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5, // Giãn dòng cho dễ đọc
              ),
            ),

            const SizedBox(height: 40),

            // Form nhập Email
            const Text(
              "Your Registered Email",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "andrew.ainsley@yourdomain.com",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const Spacer(), // Đẩy nút xuống dưới cùng

            // Nút Send OTP Code
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Xử lý gửi OTP ở đây
                  Navigator.pushNamed(context, AppRoutes.otpVerification);
                  // Navigator.pushNamed(context, AppRoutes.otpVerification); // (Sau này sẽ làm trang này)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Send OTP Code",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30), // Khoảng cách an toàn dưới đáy
          ],
        ),
      ),
    );
  }
}