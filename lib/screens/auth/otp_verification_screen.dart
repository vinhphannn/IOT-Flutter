import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cần để giới hạn ký tự nhập
import '../../routes.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // --- 1. QUẢN LÝ INPUT (4 ô) ---
  // Khai báo biến trễ (late), sẽ được khởi tạo trong initState
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  // --- 2. QUẢN LÝ TIMER ---
  int _resendSeconds = 56;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // QUAN TRỌNG: Khởi tạo các controller và focus node ở đây
    _controllers = List.generate(4, (index) => TextEditingController());
    _focusNodes = List.generate(4, (index) => FocusNode());
    
    // Bắt đầu đếm ngược
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Giải phóng bộ nhớ khi thoát màn hình để tránh rò rỉ bộ nhớ (Memory Leak)
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 56;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendSeconds > 0) {
            _resendSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  // --- 3. XỬ LÝ KHI NHẬP SỐ ---
  void _onChanged(String value, int index) {
    // Nếu nhập vào 1 số (độ dài = 1)
    if (value.length == 1) {
      // Nếu chưa phải ô cuối cùng -> Chuyển focus sang ô kế tiếp
      if (index < 3) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // Nếu là ô cuối cùng -> Ẩn bàn phím và Xác thực
        FocusScope.of(context).unfocus();
        _handleVerify();
      }
    }
    // Nếu xóa (độ dài = 0) và không phải ô đầu tiên -> Quay lui về ô trước
    else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

// Hàm giả lập xác thực OTP
  void _handleVerify() async { // <--- Thêm async
    // Ghép 4 số lại
    String otp = _controllers.map((c) => c.text).join();
    print("Verifying OTP: $otp");
    
    // 1. Hiện loading (nếu muốn làm kỹ hơn thì bọc UI bằng Stack loading như các trang trước)
    // Ở đây mình giả lập đợi 3 giây như bạn yêu cầu
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // 2. Chuyển sang trang tạo mật khẩu mới
      Navigator.pushReplacementNamed(context, AppRoutes.resetPassword);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Enter OTP Code 🔐",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Please check your email inbox for a message from Smartify. Enter the one-time verification code below.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // --- 4 Ô NHẬP OTP (TEXTFIELD THẬT) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 70, 
                  height: 70,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onChanged(value, index),
                    
                    // Cấu hình bàn phím
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    
                    // Giới hạn chỉ nhập 1 ký tự số
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    
                    // Trang trí ô nhập
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50], // Màu nền xám nhạt
                      contentPadding: EdgeInsets.zero, // Để số nằm chính giữa
                      
                      // Viền khi bình thường (Ẩn hoặc xám nhạt)
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200), 
                      ),
                      
                      // Viền khi đang nhập (Màu xanh chủ đạo)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryColor, width: 2), 
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // --- BỘ ĐẾM GIỜ & NÚT GỬI LẠI ---
            RichText(
              text: TextSpan(
                text: "You can resend the code in ",
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                children: [
                  TextSpan(
                    text: "$_resendSeconds",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
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