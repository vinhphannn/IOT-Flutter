import 'package:flutter/material.dart';
import '../../services/house_service.dart';

class JoinHomeCodeScreen extends StatefulWidget {
  const JoinHomeCodeScreen({super.key});

  @override
  State<JoinHomeCodeScreen> createState() => _JoinHomeCodeScreenState();
}

class _JoinHomeCodeScreenState extends State<JoinHomeCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final HouseService _houseService = HouseService();
  bool _isProcessing = false; // ✅ Đã thêm biến này để hết lỗi undefined

  // --- HÀM HIỆN POPUP LOADING ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B6EF6)),
              ),
              SizedBox(height: 32),
              Text(
                "Joining the Home...", 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black, 
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM XỬ LÝ KHI NHẤN NÚT JOIN ---
  // Chồng đổi tên từ _handleJoin thành _submitCode cho khớp với nút bấm của vợ
  void _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the invitation code")),
      );
      return;
    }

    _showLoadingDialog(); // Hiện popup xoay xoay
    
    try {
      bool success = await _houseService.joinHouseByCode(code);
      
      if (mounted) {
        Navigator.pop(context); // Đóng Loading
        if (success) {
          // Trả về 'true' để báo trang Home load lại danh sách nhà
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid or expired code"), 
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading nếu lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Join a Home", style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.home_work_rounded, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            const Text("Enter the Invitation Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              autofocus: true,
              textCapitalization: TextCapitalization.characters, // Tự động viết hoa cho đẹp
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                filled: true, 
                fillColor: Colors.white,
                hintText: "CODE123",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, 
              height: 55,
              child: ElevatedButton(
                onPressed: _submitCode, // ✅ Giờ đã khớp tên hàm, không còn lỗi nữa
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "Join", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}