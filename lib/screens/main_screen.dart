import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Thêm import Provider
import '../../providers/house_provider.dart'; // 2. Thêm import HouseProvider
// Import 4 trang con
import 'home/home_screen.dart';
import 'profile/account_screen.dart';
import 'smart/smart_screen.dart';
import 'report/reports_screen.dart';
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
    const ReportsScreen(),
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
        type: BottomNavigationBarType.fixed,
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
      floatingActionButton: _selectedIndex == 0 
        ? Container(
            margin: const EdgeInsets.only(bottom: 20), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. NÚT MIC (VOICE ASSISTANT)
                FloatingActionButton(
                  heroTag: "btn_mic",
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.voiceAssistant);
                  },
                  backgroundColor: Colors.blue[50], 
                  mini: true, 
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: Icon(Icons.mic, color: primaryColor),
                ),
                
                const SizedBox(width: 16),
                
                // 2. NÚT ADD DEVICE - ĐÃ THÊM CHECK QUYỀN
                FloatingActionButton(
                  heroTag: "btn_add",
                  onPressed: () {
                    // 👇 BẮT ĐẦU CHECK QUYỀN VỢ NHÉ
                    final houseProvider = context.read<HouseProvider>();
                    final String userRole = (houseProvider.currentRole ?? "MEMBER").toUpperCase();

                    if (userRole == "OWNER" || userRole == "ADMIN") {
                      // ✅ ĐỦ QUYỀN -> CHO VÀO TRANG THÊM THIẾT BỊ
                      Navigator.pushNamed(context, AppRoutes.addDevice);
                    } else {
                      // ❌ KHÔNG ĐỦ QUYỀN -> HIỆN THÔNG BÁO
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bạn không có quyền thêm thiết bị trong nhà này!"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
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
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}