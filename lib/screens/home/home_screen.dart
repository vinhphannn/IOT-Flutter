import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến quản lý tab BottomBar (Mặc định là 0 - Home)
  int _selectedIndex = 0;
  
  // Biến quản lý phòng đang chọn
  int _selectedRoomIndex = 0;
  final List<String> _rooms = ["All Rooms", "Living Room", "Bedroom", "Kitchen", "Garage"];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (My Home + Avatar)
              _buildHeader(),

              const SizedBox(height: 24),

              // 2. WEATHER WIDGET (Thẻ thời tiết)
              _buildWeatherCard(),

              const SizedBox(height: 30),

              // 3. TITLE + FILTER ROOMS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "All Devices",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.more_vert, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 16),
              
              // List chọn phòng (Scroll ngang)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedRoomIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoomIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _rooms[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 50),

              // 4. EMPTY STATE (Chưa có thiết bị)
              _buildEmptyState(primaryColor),
              
              const SizedBox(height: 80), // Khoảng trống để không bị nút đè
            ],
          ),
        ),
      ),

      // 5. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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

      // 6. FLOATING ACTION BUTTONS (MIC & ADD)
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút Mic nhỏ
          FloatingActionButton(
            heroTag: "mic",
            onPressed: () {},
            backgroundColor: Colors.blue[50], // Màu nền nhạt
            mini: true, // Size nhỏ
            elevation: 2,
            child: Icon(Icons.mic, color: primaryColor),
          ),
          const SizedBox(width: 16),
          // Nút Cộng to
          FloatingActionButton(
            heroTag: "add",
            onPressed: () {
              // Xử lý thêm thiết bị sau này
            },
            backgroundColor: primaryColor,
            elevation: 4,
            shape: const CircleBorder(), // Tròn vo
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  // --- Widget Con: Header ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              "My Home",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 28),
          ],
        ),
        Row(
          children: [
            // Robot Icon (Giả lập)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            // Notification Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), // Xám siêu nhạt
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, color: Colors.black87),
            ),
          ],
        )
      ],
    );
  }

  // --- Widget Con: Thẻ thời tiết ---
  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B6EF6), Color(0xFF7B96FF)], // Xanh đậm -> nhạt
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B6EF6).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Stack(
        children: [
          // Nội dung bên trái
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("20°C", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text("New York City, USA", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const Text("Today Cloudy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              
              // Thông số nhỏ (AQI, Humidity, Wind)
              Row(
                children: [
                  _buildWeatherInfo(Icons.air, "AQI 92"),
                  const SizedBox(width: 15),
                  _buildWeatherInfo(Icons.water_drop_outlined, "78%"),
                  const SizedBox(width: 15),
                  _buildWeatherInfo(Icons.wind_power, "2.0 m/s"),
                ],
              )
            ],
          ),

          // Hình minh họa bên phải (Mặt trời + Mây)
          Positioned(
            right: -20,
            top: -20,
            child: SizedBox(
              width: 160,
              height: 160,
              // Bạn thay bằng Image.asset('assets/images/weather_cloud.png') nhé
              // Ở đây anh dùng Icon ghép tạm để demo
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: 20, top: 20,
                    child: Icon(Icons.wb_sunny, size: 80, color: Colors.amber[400]),
                  ),
                  Positioned(
                    bottom: 20, left: 10,
                    child: Icon(Icons.cloud, size: 100, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // --- Widget Con: Empty State ---
  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        children: [
          // Hình minh họa (Clipboard)
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 80, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
              Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 90, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
                  ),
                  child: const Center(
                    child: Icon(Icons.paste_rounded, size: 40, color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "No Devices",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You haven't added a device yet.",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Nút Add Device
          SizedBox(
            width: 180,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
            ),
          )
        ],
      ),
    );
  }
}