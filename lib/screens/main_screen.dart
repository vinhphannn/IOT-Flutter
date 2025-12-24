import 'package:flutter/material.dart';
// Import 4 trang con vào đây
import 'home/home_screen.dart';
import 'profile/account_screen.dart'; 

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
    const Center(child: Text("Smart Page (Coming Soon)")), // Trang 1: Smart (Chưa làm thì để tạm Text)
    const Center(child: Text("Reports Page (Coming Soon)")), // Trang 2: Reports
    const AccountScreen(), // Trang 3: Account (Vừa tạo xong)
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      // Body sẽ thay đổi tùy theo _selectedIndex
      body: _pages[_selectedIndex],

      // BottomNavigationBar dùng chung nằm ở đây
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
      
      // Nút tròn ở giữa (Floating Button) chỉ hiện ở trang Home, hoặc hiện ở mọi trang tùy vợ
      // Nếu muốn chỉ hiện ở Home thì bọc trong if:
      floatingActionButton: _selectedIndex == 0 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "mic", onPressed: () {},
                backgroundColor: Colors.blue[50], mini: true, elevation: 2,
                child: Icon(Icons.mic, color: primaryColor),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: "add", onPressed: () {
                   Navigator.pushNamed(context, '/add-device'); // Nhớ check lại route name nha
                },
                backgroundColor: primaryColor, elevation: 4, shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ],
          ) 
        : null,
    );
  }
}