import 'package:flutter/material.dart';
// Import 2 file Tab con
import 'tabs/nearby_scan_tab.dart';
import 'tabs/manual_add_tab.dart'; // Đảm bảo vợ đã có file này trong thư mục tabs rồi nhé
import '../../routes.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  // Chỉ còn lại biến để chuyển Tab
  int _selectedTab = 0; // 0: Nearby, 1: Manual

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Device",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.scanQR);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 1. THANH ĐIỀU HƯỚNG TAB (GIỮ NGUYÊN)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabItem("Nearby Devices", 0, primaryColor),
                _buildTabItem("Add Manual", 1, primaryColor),
              ],
            ),
          ),

          // 2. NỘI DUNG CHÍNH (THAY ĐỔI THEO TAB)
          Expanded(
            child: _selectedTab == 0
                // Tab 0: Gọi file NearbyScanTab
                ? const NearbyScanTab() 
                // Tab 1: Gọi file ManualAddTab (Vợ nhớ chuyển file manual_add_tab.dart vào thư mục tabs luôn cho gọn nhé)
                : const ManualAddTab(), 
          ),
        ],
      ),
    );
  }

  // Widget vẽ cái nút Tab
  Widget _buildTabItem(String text, int index, Color primaryColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Thêm hiệu ứng chuyển mượt
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}