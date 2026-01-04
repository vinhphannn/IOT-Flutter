import 'package:flutter/material.dart';
// Import 4 trang con
import 'home/home_screen.dart';
import 'profile/account_screen.dart';
import 'smart/smart_screen.dart';
// Import routes để điều hướng
import '../routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Trang hiện tại đang chọn

  // Danh sách 4 màn hình
  final List<Widget> _pages = [
    const HomeScreen(), // Trang 0: Home
    const SmartScreen(),// Trang 1
    const Center(child: Text("Reports Page (Coming Soon)")), // Trang 2
    const AccountScreen(), // Trang 3: Account
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      // Body sẽ thay đổi tùy theo _selectedIndex
      body: _pages[_selectedIndex],

      // BottomNavigationBar dùng chung
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Quan trọng để hiện đủ 4 nút
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Smart"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
        ],
      ),
      
      // --- CẤU HÌNH NÚT NỔI (FAB) ---
      // Chỉ hiện ở trang Home (index == 0)
      floatingActionButton: _selectedIndex == 0 
        ? Container(
            // Thêm khoảng cách dưới đáy để nút không dính sát thanh điều hướng
            margin: const EdgeInsets.only(bottom: 20), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. NÚT MIC (VOICE ASSISTANT)
                FloatingActionButton(
                  heroTag: "btn_mic", // Tag riêng để tránh lỗi
                  onPressed: () {
                    // Chuyển sang trang Voice Assistant
                    Navigator.pushNamed(context, AppRoutes.voiceAssistant);
                  },
                  backgroundColor: Colors.blue[50], 
                  mini: true, 
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: Icon(Icons.mic, color: primaryColor),
                ),
                
                const SizedBox(width: 16),
                
                // 2. NÚT ADD DEVICE
                FloatingActionButton(
                  heroTag: "btn_add", // Tag riêng
                  onPressed: () {
                     Navigator.pushNamed(context, AppRoutes.addDevice);
                  },
                  backgroundColor: primaryColor, 
                  elevation: 4, 
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ],
            ),
          ) 
        : null,
      
      // Định vị trí nút nổi ở góc dưới bên phải
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}