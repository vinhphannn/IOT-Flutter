import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'join_home_code_screen.dart';
import '../../services/house_service.dart';

class JoinHomeScanScreen extends StatefulWidget {
  const JoinHomeScanScreen({super.key});

  @override
  State<JoinHomeScanScreen> createState() => _JoinHomeScanScreenState();
}

class _JoinHomeScanScreenState extends State<JoinHomeScanScreen> {
  bool _isProcessing = false;
  final HouseService _houseService = HouseService();

  // --- HÀM HIỆN POPUP LOADING ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B6EF6))),
              SizedBox(height: 32),
              Text("Joining the Home...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
  }

  // Khi camera nhận diện được mã QR
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final String? code = capture.barcodes.first.rawValue;
    
    if (code != null) {
      setState(() => _isProcessing = true);
      _handleJoin(code);
    }
  }

void _handleJoin(String code) async {
    _showLoadingDialog(); // Hiện xoay xoay
    bool success = await _houseService.joinHouseByCode(code);
    
    if (mounted) {
      Navigator.pop(context); // Đóng Loading
      if (success) {
        // 👇 Gửi tín hiệu 'true' để báo trang Home là đã Join thành công
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR Code"), backgroundColor: Colors.red)
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Khung ngắm
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(20)),
            ),
          ),
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: Column(
              children: [
                const Text("Can't scan the QR code?", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinHomeCodeScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Enter the Invitation Code", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}