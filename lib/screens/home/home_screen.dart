import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS CÁC FILE CỦA VỢ ---
import '../../routes.dart';
import '../../services/room_service.dart';
import '../../services/house_service.dart'; 
import '../../models/device_model.dart';
import '../../models/house_model.dart';
import '../../widgets/device_card.dart';
import '../../widgets/summary_card.dart';
import 'category_devices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 1. BIẾN QUẢN LÝ NHÀ & PHÒNG ---
  List<House> _houses = [];
  House? _currentHouse; 
  bool _isLoadingHouse = true;

  int _selectedRoomIndex = 0;
  List<String> _rooms = ["All Rooms"];
  
  // Danh sách thiết bị hiển thị
  List<Device> _homeDisplayDevices = [];

  // --- 2. BIẾN THỜI TIẾT ---
  bool _isLoadingWeather = true;
  String _temp = "--"; 
  String _cityName = "Locating..."; 
  String _weatherDesc = "Checking...";
  String _humidity = "-"; 
  String _windSpeed = "-"; 
  String _weatherIconCode = "02d";
  final String _apiKey = "9d7d651e4671cadec782b9a990c7d992"; // Key Free của vợ

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initHomeData(); // Bắt đầu tải dữ liệu
  }

  // --- LOGIC TỔNG: KHỞI TẠO DỮ LIỆU ---
  Future<void> _initHomeData() async {
    await _fetchHouses();
    _filterDevices(); // Lọc thiết bị lần đầu
  }

  // ==========================================
  // PHẦN A: LOGIC GỌI API (QUAN TRỌNG)
  // ==========================================

  // 1. LẤY DANH SÁCH NHÀ
  Future<void> _fetchHouses() async {
    try {
      HouseService houseService = HouseService();
      List<House> houses = await houseService.fetchMyHouses();

      if (mounted) {
        setState(() {
          _houses = houses;
          if (_houses.isNotEmpty) {
            // Mặc định chọn nhà đầu tiên
            _currentHouse = _houses[0];
            // Lưu lại ID nhà này để dùng cho các màn hình khác
            _saveCurrentHouseId(_currentHouse!.id);
            _isLoadingHouse = false;
          } else {
             // Trường hợp User chưa có nhà nào (Hiếm khi xảy ra vì đã qua Setup)
             _isLoadingHouse = false;
          }
        });

        // Có nhà rồi thì đi lấy Phòng của nhà đó
        if (_currentHouse != null) {
          await _fetchRoomsForHouse(_currentHouse!.id);
        }
      }
    } catch (e) {
      // --- XỬ LÝ LỖI 401 (AUTO LOGOUT) ---
      if (e.toString().contains("UNAUTHORIZED")) {
        debugPrint("Token hết hạn hoặc User bị xóa. Đăng xuất...");
        if (mounted) {
           // Đá về màn hình Login Options và xóa sạch lịch sử điều hướng
           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginOptions, (route) => false);
        }
        return;
      }
      
      debugPrint("Lỗi lấy danh sách nhà: $e");
      if (mounted) setState(() => _isLoadingHouse = false);
    }
  }

  // 2. LẤY DANH SÁCH PHÒNG THEO ID NHÀ
  Future<void> _fetchRoomsForHouse(int houseId) async {
    try {
      RoomService roomService = RoomService();
      List<String> roomsFromDb = await roomService.fetchRoomNamesByHouse(houseId);
      
      if (mounted) {
        setState(() {
          // Luôn giữ tab "All Rooms" ở đầu
          _rooms = ["All Rooms", ...roomsFromDb];
          _selectedRoomIndex = 0; // Reset về tab đầu tiên
        });
        _filterDevices(); // Filter lại thiết bị
      }
    } catch (e) {
      debugPrint("Lỗi lấy phòng: $e");
    }
  }

  // 3. XỬ LÝ KHI NGƯỜI DÙNG ĐỔI NHÀ (DROPDOWN)
  void _onHouseSelected(House house) async {
    if (_currentHouse?.id == house.id) return; // Chọn lại cái cũ thì bỏ qua

    setState(() {
      _currentHouse = house;
      _isLoadingHouse = true; // Hiện loading nhẹ ở header
    });

    await _saveCurrentHouseId(house.id);

    // Load lại phòng của nhà mới
    await _fetchRoomsForHouse(house.id);
    
    setState(() => _isLoadingHouse = false);
  }

  Future<void> _saveCurrentHouseId(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentHouseId', id);
  }

  // ==========================================
  // PHẦN B: LOGIC UI & THỜI TIẾT
  // ==========================================

  // Lọc thiết bị hiển thị theo Tab Phòng
  void _filterDevices() {
    setState(() {
      if (_selectedRoomIndex == 0) {
        _homeDisplayDevices = demoDevices; // Hiện tất cả
      } else {
        String room = _rooms[_selectedRoomIndex];
        // Lọc thiết bị có tên phòng trùng với tab đang chọn
        _homeDisplayDevices = demoDevices.where((d) => d.room == room).toList();
      }
    });
  }

  void _navigateToCategory(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDevicesScreen(categoryType: type, title: title),
      ),
    );
  }

  // --- LOGIC THỜI TIẾT (OpenWeatherMap) ---
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
              const Text("Please activate location to see local weather.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
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

  // ==========================================
  // PHẦN C: GIAO DIỆN CHÍNH (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Đếm số lượng thiết bị (Dựa trên Demo Data)
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
              // --- 1. HEADER (CHỌN NHÀ) ---
              _buildHeader(),
              
              const SizedBox(height: 24),
              
              // --- 2. THỜI TIẾT ---
              _buildWeatherCard(), 
              
              const SizedBox(height: 24),

              // --- 3. SUMMARY CARDS ---
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

              // --- 4. DANH SÁCH THIẾT BỊ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("All Devices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  // Nút Add Device
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

              // --- 5. BỘ LỌC PHÒNG (TAB NGANG) ---
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedRoomIndex == index;
                    // Đếm số lượng (Demo)
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

              // --- 6. GRID HIỂN THỊ THIẾT BỊ ---
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

  // --- WIDGET HEADER (DROPDOWN CHỌN NHÀ) ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dropdown Menu
        PopupMenuButton<House>(
          onSelected: _onHouseSelected,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (BuildContext context) {
            return _houses.map((House house) {
              return PopupMenuItem<House>(
                value: house,
                child: Row(
                  children: [
                    Icon(
                      Icons.home, 
                      color: house.id == _currentHouse?.id ? Colors.blue : Colors.grey,
                      size: 20
                    ),
                    const SizedBox(width: 10),
                    Text(
                      house.name,
                      style: TextStyle(
                        fontWeight: house.id == _currentHouse?.id ? FontWeight.bold : FontWeight.normal,
                        color: house.id == _currentHouse?.id ? Colors.blue : Colors.black87
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: Row(
            children: [
              Text(
                _currentHouse?.name ?? "Loading...", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (_isLoadingHouse) 
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.keyboard_arrow_down, size: 28),
            ],
          ),
        ),

        // Icon Chat & Notify
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
  
  // --- WIDGET THỜI TIẾT ---
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

  // --- WIDGET TRỐNG (EMPTY STATE) ---
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