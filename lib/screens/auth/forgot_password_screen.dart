import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/auth/forgot-password', 
        { "email": email },
        withToken: false
      );

      if (response.statusCode == 200) {
        if (mounted) {
          print("🚀 Gửi sang OTP với email: $email"); // Log kiểm tra
          Navigator.pushNamed(
            context, 
            AppRoutes.otpVerification,
            arguments: { 'email': email } // Gửi Map
          );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP sent successfully!"), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email not found."), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isLoading = false);
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
            const Text("Forgot Your Password? 🔑", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            Text("Enter your email to receive an OTP code.", style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 40),

            const Text("Your Registered Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "example@domain.com",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 2),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send OTP Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}