import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../routes.dart';
import '../../services/room_service.dart';
// Import các file mới (Vợ đảm bảo đã tạo các file này rồi nhé)
import '../../models/device_model.dart';
import '../../widgets/device_card.dart';
import '../../widgets/summary_card.dart';
import 'category_devices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 1. BIẾN UI ---
  int _selectedRoomIndex = 0;
  List<String> _rooms = ["All Rooms"];
  
  // Danh sách hiển thị ở trang Home (Lọc theo phòng)
  List<Device> _homeDisplayDevices = [];

  // --- 2. BIẾN THỜI TIẾT (Đã khôi phục đầy đủ) ---
  bool _isLoadingWeather = true;
  String _temp = "--"; 
  String _cityName = "Locating..."; 
  String _weatherDesc = "Checking...";
  String _humidity = "-"; 
  String _windSpeed = "-"; 
  String _weatherIconCode = "02d";
  
  // API Key (Vợ nhớ giữ bí mật nhé)
  final String _apiKey = "9d7d651e4671cadec782b9a990c7d992";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Gọi hàm lấy vị trí thật
    _fetchRoomsData();
    _filterDevices(); // Lọc thiết bị lần đầu
  }

  // --- LOGIC LỌC THIẾT BỊ ---
  void _filterDevices() {
    setState(() {
      if (_selectedRoomIndex == 0) {
        _homeDisplayDevices = demoDevices;
      } else {
        String room = _rooms[_selectedRoomIndex];
        _homeDisplayDevices = demoDevices.where((d) => d.room == room).toList();
      }
    });
  }

  // --- LOGIC LẤY PHÒNG TỪ SERVER ---
  Future<void> _fetchRoomsData() async {
    try {
      RoomService roomService = RoomService();
      List<String> roomsFromDb = await roomService.fetchRooms();
      if (mounted) {
        setState(() {
          _rooms = ["All Rooms", ...roomsFromDb];
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy phòng: $e");
    }
  }

  // --- LOGIC CHUYỂN TRANG CATEGORY ---
  void _navigateToCategory(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDevicesScreen(categoryType: type, title: title),
      ),
    );
  }

  // --- 3. LOGIC THỜI TIẾT (ĐÃ KHÔI PHỤC) ---
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _cityName = "GPS Off"; _isLoadingWeather = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) _showLocationDialog(); 
    } else if (permission == LocationPermission.deniedForever) {
      setState(() { _cityName = "Blocked"; _isLoadingWeather = false; });
    } else {
      _fetchWeatherData(); 
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoadingWeather = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey');
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _temp = data['main']['temp'].round().toString();
            _cityName = data['name'];
            _weatherDesc = data['weather'][0]['main'];
            _humidity = data['main']['humidity'].toString();
            _windSpeed = data['wind']['speed'].toString();
            _weatherIconCode = data['weather'][0]['icon'];
            _isLoadingWeather = false;
          });
        }
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    if (mounted) {
      setState(() {
        _temp = "28"; _cityName = "Ho Chi Minh"; _weatherDesc = "Clouds";
        _humidity = "75"; _windSpeed = "3.5"; _weatherIconCode = "02d";
        _isLoadingWeather = false; 
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: Color(0xFF4B6EF6), shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Enable Location", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Please activate location to see local weather.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    LocationPermission permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                      _fetchWeatherData();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B6EF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Text("Enable Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _useFallbackData();
                },
                child: const Text("Not Now", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Đếm số lượng cho Summary Cards
    int lightCount = demoDevices.where((d) => d.type == 'Light').length;
    int cameraCount = demoDevices.where((d) => d.type == 'Camera').length;
    int electricalCount = demoDevices.where((d) => d.type == 'AC' || d.type == 'Router' || d.type == 'Speaker').length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Widget Thời tiết (Đã khôi phục)
              _buildWeatherCard(), 
              
              const SizedBox(height: 24),

              // --- SUMMARY CARDS ---
              Row(
                children: [
                  SummaryCard(
                    icon: Icons.lightbulb_outline, title: "Lighting", subtitle: "$lightCount lights",
                    bgColor: Colors.amber[50]!, iconColor: Colors.amber[800]!,
                    onTap: () => _navigateToCategory('Light', 'Lighting'),
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    icon: Icons.videocam_outlined, title: "Cameras", subtitle: "$cameraCount cameras",
                    bgColor: Colors.purple[50]!, iconColor: Colors.purple[400]!,
                    onTap: () => _navigateToCategory('Camera', 'Cameras'),
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    icon: Icons.electrical_services, title: "Electrical", subtitle: "$electricalCount devices",
                    bgColor: Colors.orange[50]!, iconColor: Colors.orange[800]!,
                    onTap: () => _navigateToCategory('AC', 'Electrical'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- HEADER DANH SÁCH ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("All Devices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  // Nút Add nhỏ
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.addDevice),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: primaryColor, size: 20),
                          const SizedBox(width: 4),
                          Text("Add", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- BỘ LỌC PHÒNG ---
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedRoomIndex == index;
                    int count = index == 0 
                      ? demoDevices.length 
                      : demoDevices.where((d) => d.room == _rooms[index]).length;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoomIndex = index;
                          _filterDevices();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                        ),
                        child: Text(
                          "${_rooms[index]} ($count)",
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

              const SizedBox(height: 20),

              // --- GRID THIẾT BỊ ---
              _homeDisplayDevices.isEmpty
                  ? _buildEmptyState(primaryColor)
                  : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _homeDisplayDevices.length,
                      itemBuilder: (context, index) {
                        return DeviceCard(
                          device: _homeDisplayDevices[index],
                          showRoomInfo: false,
                        );
                      },
                    ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text("My Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 28),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.notification),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.black87),
                    Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
  
  // Widget Thời tiết ĐẦY ĐỦ (Đã khôi phục)
  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity, height: 180, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B6EF6), Color(0xFF7B96FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF4B6EF6).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: _isLoadingWeather 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_temp°C", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_cityName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("Today $_weatherDesc", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildWeatherInfo(Icons.air, "AQI 90"),
                      const SizedBox(width: 15),
                      _buildWeatherInfo(Icons.water_drop_outlined, "$_humidity%"),
                      const SizedBox(width: 15),
                      _buildWeatherInfo(Icons.wind_power, "$_windSpeed m/s"),
                    ],
                  )
                ],
              ),
              Positioned(
                right: -10, top: -10,
                child: SizedBox(
                  width: 140, height: 140,
                  child: Image.network(
                    "https://openweathermap.org/img/wn/$_weatherIconCode@4x.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.cloud, size: 100, color: Colors.white.withOpacity(0.8)),
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

  // Widget Empty State đầy đủ (Đã khôi phục)
  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 80, height: 100,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                ),
              ),
              Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 90, height: 110,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                  child: const Center(child: Icon(Icons.paste_rounded, size: 40, color: Colors.blueAccent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("No Devices Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("No devices in this room.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            width: 180, height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addDevice);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 4, shadowColor: primaryColor.withOpacity(0.4)),
            ),
          )
        ],
      ),
    );
  }
}