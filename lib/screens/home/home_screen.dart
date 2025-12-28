import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes.dart';
import '../../services/room_service.dart';
import '../../services/house_service.dart';
import '../../models/device_model.dart';
import '../../models/house_model.dart';
import '../../widgets/device_card.dart';
import '../../widgets/summary_card.dart';
import '../device/category_devices_screen.dart';

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

  // Danh sách thiết bị
  List<Device> _allDevices = [];
  List<Device> _homeDisplayDevices = [];

  // --- 2. BIẾN THỜI TIẾT ---
  bool _isLoadingWeather = true;
  String _temp = "--";
  String _cityName = "Locating...";
  String _weatherDesc = "Checking...";
  String _humidity = "-";
  String _windSpeed = "-";
  String _weatherIconCode = "02d";

  final String _apiKey = "9d7d651e4671cadec782b9a990c7d992";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initHomeData();
  }

  // --- LOGIC KHỞI TẠO DỮ LIỆU ---
  Future<void> _initHomeData() async {
    await _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    try {
      HouseService houseService = HouseService();
      List<House> houses = await houseService.fetchMyHouses();

      if (mounted) {
        setState(() {
          _houses = houses;
          if (_houses.isNotEmpty) {
            _currentHouse = _houses[0];
            _saveCurrentHouseId(_currentHouse!.id);
            _isLoadingHouse = false;
          } else {
            _isLoadingHouse = false;
          }
        });

        if (_currentHouse != null) {
          await _fetchRoomsAndDevices(_currentHouse!.id);
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy danh sách nhà: $e");
      if (mounted) setState(() => _isLoadingHouse = false);

      if (e.toString().contains("401") || e.toString().contains("UNAUTHORIZED")) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.loginOptions, (route) => false);
        }
      }
    }
  }

Future<void> _fetchRoomsAndDevices(int houseId) async {
    final houseService = HouseService();
    final roomService = RoomService();

    List<String> roomsFromDb = [];
    List<Device> devicesFromDb = [];

    // 1. Lấy danh sách PHÒNG trước (Quan trọng)
    try {
      roomsFromDb = await roomService.fetchRoomNamesByHouse(houseId);
    } catch (e) {
      debugPrint("❌ Lỗi lấy phòng: $e");
    }

    // 2. Lấy danh sách THIẾT BỊ sau
    try {
      // Nếu HouseService chưa chuẩn, nó sẽ báo lỗi ở đây nhưng ko làm mất danh sách phòng
      devicesFromDb = await houseService.fetchDevicesByHouseId(houseId);
    } catch (e) {
      debugPrint("❌ Lỗi lấy thiết bị: $e");
    }

    if (mounted) {
      setState(() {
        // Luôn cập nhật UI dù có dữ liệu hay không
        _rooms = ["All Rooms", ...roomsFromDb];
        _allDevices = devicesFromDb;
        _selectedRoomIndex = 0;
      });
      _filterDevices();
    }
  }

  void _onHouseSelected(House house) async {
    if (_currentHouse?.id == house.id) return;

    setState(() {
      _currentHouse = house;
      _isLoadingHouse = true;
    });

    await _saveCurrentHouseId(house.id);
    await _fetchRoomsAndDevices(house.id);

    if (mounted) setState(() => _isLoadingHouse = false);
  }

  Future<void> _saveCurrentHouseId(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentHouseId', id);
  }

  // --- SỬA LỖI 1: Đổi d.room thành d.roomName ---
  void _filterDevices() {
    setState(() {
      if (_selectedRoomIndex == 0) {
        _homeDisplayDevices = _allDevices;
      } else {
        String roomName = _rooms[_selectedRoomIndex];
        // Sửa ở đây: dùng roomName thay vì room
        _homeDisplayDevices = _allDevices.where((d) => d.roomName == roomName).toList();
      }
    });
  }

  // --- SỬA LỖI 2: Truyền thêm tham số allDevices ---
  void _navigateToCategory(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDevicesScreen(
          categoryType: type,
          title: title,
          allDevices: _allDevices, // <-- Đã thêm dòng này để hết lỗi missing argument
        ),
      ),
    );
  }

  // --- LOGIC THỜI TIẾT ---
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() { _cityName = "GPS Off"; _isLoadingWeather = false; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showLocationDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() { _cityName = "Blocked"; _isLoadingWeather = false; });
      return;
    }

    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoadingWeather = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey');

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
        _temp = "28";
        _cityName = "Ho Chi Minh";
        _weatherDesc = "Clouds";
        _humidity = "75";
        _windSpeed = "3.5";
        _weatherIconCode = "02d";
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
              const Icon(Icons.location_on, color: Color(0xFF4B6EF6), size: 50),
              const SizedBox(height: 16),
              const Text("Enable Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Please enable location to see local weather.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _useFallbackData();
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openAppSettings();
                      _checkLocationPermission();
                    },
                    child: const Text("Settings",
                        style: TextStyle(
                            color: Color(0xFF4B6EF6),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Sửa lại: Dùng || để đếm cả 2 loại key
    int lightCount =
        _allDevices.where((d) => d.type == 'RELAY' || d.type == 'Light').length;
    int socketCount = _allDevices.where((d) => d.type == 'SOCKET').length;
    int sensorCount = _allDevices.where((d) => d.type == 'SENSOR').length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_currentHouse != null) {
              await _fetchRoomsAndDevices(_currentHouse!.id);
            } else {
              await _fetchHouses();
            }
          },
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildWeatherCard(),
                const SizedBox(height: 24),

                // --- SUMMARY CARDS ---
                Row(
                  children: [
                    SummaryCard(
                        icon: Icons.lightbulb_outline,
                        title: "Lighting",
                        subtitle: "$lightCount lights",
                        bgColor: Colors.amber[50]!,
                        iconColor: Colors.amber[800]!,
                        onTap: () => _navigateToCategory('RELAY', 'Lighting')),
                    const SizedBox(width: 12),
                    SummaryCard(
                        icon: Icons.power,
                        title: "Sockets",
                        subtitle: "$socketCount devices",
                        bgColor: Colors.purple[50]!,
                        iconColor: Colors.purple[400]!,
                        onTap: () => _navigateToCategory('SOCKET', 'Sockets')),
                    const SizedBox(width: 12),
                    SummaryCard(
                        icon: Icons.sensors,
                        title: "Sensors",
                        subtitle: "$sensorCount units",
                        bgColor: Colors.orange[50]!,
                        iconColor: Colors.orange[800]!,
                        onTap: () => _navigateToCategory('SENSOR', 'Sensors')),
                  ],
                ),

                const SizedBox(height: 24),

                // --- HEADER DANH SÁCH ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("All Devices",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addDevice),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: primaryColor, size: 20),
                            const SizedBox(width: 4),
                            Text("Add",
                                style: TextStyle(
                                    color: primaryColor, fontWeight: FontWeight.bold)),
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
                      
                      // SỬA LỖI 1 ở đây nữa: dùng roomName
                      int count = index == 0
                          ? _allDevices.length
                          : _allDevices.where((d) => d.roomName == _rooms[index]).length;

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
                            border: Border.all(
                                color: isSelected ? primaryColor : Colors.grey.shade300),
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
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _homeDisplayDevices.length,
                        itemBuilder: (context, index) {
                          return DeviceCard(
                            device: _homeDisplayDevices[index],
                            showRoomInfo: _selectedRoomIndex == 0,
                          );
                        },
                      ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS CON (Đã sửa lỗi deprecated withOpacity -> withValues) ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_houses.isEmpty)
          const Text("My Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        else
          PopupMenuButton<House>(
            onSelected: _onHouseSelected,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => _houses.map((h) => PopupMenuItem<House>(
                  value: h,
                  child: Row(
                    children: [
                      Icon(Icons.home,
                          color: h.id == _currentHouse?.id
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          size: 20),
                      const SizedBox(width: 10),
                      Text(h.name,
                          style: TextStyle(
                              fontWeight: h.id == _currentHouse?.id
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                )).toList(),
            child: Row(
              children: [
                Text(
                  _currentHouse?.name ?? "Loading...",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _isLoadingHouse
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.keyboard_arrow_down, size: 28),
              ],
            ),
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
                decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.black87),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle)),
                    )
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF4B6EF6), Color(0xFF7B96FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        // Sửa lỗi deprecated: withOpacity -> withValues
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4B6EF6).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
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
                        Text("$_temp°C",
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_cityName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text("Today $_weatherDesc",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
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
                  right: -10,
                  top: -10,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.network(
                      "https://openweathermap.org/img/wn/$_weatherIconCode@4x.png",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.cloud,
                          size: 100,
                          // Sửa lỗi deprecated
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))
    ]);
  }

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
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300))),
              ),
              Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      // Sửa lỗi deprecated
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10)
                      ]),
                  child: const Center(
                      child: Icon(Icons.paste_rounded,
                          size: 40, color: Colors.blueAccent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("No Devices Found",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("No devices in this room.",
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addDevice),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  // Sửa lỗi deprecated
                  shadowColor: primaryColor.withValues(alpha: 0.4)),
            ),
          )
        ],
      ),
    );
  }
}