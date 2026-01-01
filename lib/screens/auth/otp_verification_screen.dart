import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../routes.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  int _resendSeconds = 56;
  Timer? _timer;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Nhận dữ liệu từ màn hình trước
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['email'] != null) {
      _email = args['email'];
      print("✅ OTP Screen: Đã nhận được Email: $_email");
    } else if (args is String) {
      _email = args; // Fallback nếu lỡ gửi String
      print("⚠️ OTP Screen: Nhận được Email dạng String: $_email");
    } else {
      print("❌ OTP Screen: CRITICAL ERROR - Args is NULL!");
      
      // Nếu không có email, hiển thị lỗi và bắt quay lại ngay lập tức
      // Dùng Future.microtask để tránh lỗi setState khi đang build
      Future.microtask(() {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: const Text("Email not found. Please try again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                    Navigator.pop(context); // Quay về màn nhập Email
                  },
                  child: const Text("Go Back"),
                )
              ],
            ),
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 56);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendSeconds > 0) _resendSeconds--;
          else _timer?.cancel();
        });
      }
    });
  }

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
        _handleVerify();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _handleVerify() async {
    String otp = _controllers.map((c) => c.text).join();
    
    if (otp.length < 6) return;

    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Missing Email! Please go back."), backgroundColor: Colors.red)
      );
      return;
    }

    print("🚀 Chuyển sang NewPassword với: Email=$_email, OTP=$otp");

    Navigator.pushReplacementNamed(
      context, 
      AppRoutes.resetPassword, // Đảm bảo tên route này đúng trong routes.dart
      arguments: {
        "email": _email,
        "otp": otp 
      }
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Enter OTP Code 🔐",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              "We sent a code to ${_email ?? 'your email'}.\nPlease check your inbox.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onChanged(value, index),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            RichText(
              text: TextSpan(
                text: "You can resend the code in ",
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                children: [
                  TextSpan(
                    text: "$_resendSeconds",
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " seconds"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _resendSeconds == 0 ? _startResendTimer : null,
              child: Text(
                "Resend code",
                style: TextStyle(
                  color: _resendSeconds == 0 ? primaryColor : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}