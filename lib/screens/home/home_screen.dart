import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http;     
import '../../routes.dart';
import '../../services/room_service.dart'; // Import Service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 1. BIẾN UI ---
  // (Đã xóa _selectedIndex vì không dùng nữa)
  int _selectedRoomIndex = 0;
  
  // Mặc định lúc đầu chỉ có "All Rooms"
  List<String> _rooms = ["All Rooms"]; 

  // --- 2. BIẾN THỜI TIẾT ---
  bool _isLoadingWeather = true;
  String _temp = "--"; 
  String _cityName = "Locating..."; 
  String _weatherDesc = "Checking..."; 
  String _humidity = "-"; 
  String _windSpeed = "-"; 
  String _weatherIconCode = "02d"; 

  // API Key
  final String _apiKey = "9d7d651e4671cadec782b9a990c7d992"; 

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Lấy thời tiết
    _fetchRoomsData();          // Lấy danh sách phòng
  }

  // --- HÀM MỚI: LẤY DANH SÁCH PHÒNG TỪ BACKEND ---
  Future<void> _fetchRoomsData() async {
    try {
      RoomService roomService = RoomService();
      List<String> roomsFromDb = await roomService.fetchRooms();

      if (mounted) {
        setState(() {
          // Giữ lại "All Rooms" ở đầu, nối thêm danh sách từ DB vào
          _rooms = ["All Rooms", ...roomsFromDb];
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy phòng: $e");
    }
  }

  // --- 3. LOGIC KIỂM TRA QUYỀN ---
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    debugPrint("🔵 [DEBUG] Bắt đầu kiểm tra quyền vị trí...");

    // 1. Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _cityName = "GPS Off"; _isLoadingWeather = false; });
      return;
    }

    // 2. Check Quyền
    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      if (mounted) _showLocationDialog(); 
    } else if (permission == LocationPermission.deniedForever) {
      setState(() { _cityName = "Blocked"; _isLoadingWeather = false; });
    } else {
      _fetchWeatherData(); 
    }
  }

  // --- 4. HÀM GỌI API THỜI TIẾT ---
  Future<void> _fetchWeatherData() async {
    setState(() => _isLoadingWeather = true);
    try {
      debugPrint("🚀 [DEBUG] Đang lấy tọa độ GPS...");
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey'
      );

      debugPrint("🌐 [DEBUG] Đang gọi API: $url");
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
        // Fallback Demo Mode
        if (mounted) {
          setState(() {
            _temp = "28"; 
            _cityName = "Go Vap, VN"; 
            _weatherDesc = "Clouds";
            _humidity = "75";
            _windSpeed = "3.5";
            _weatherIconCode = "02d"; 
            _isLoadingWeather = false; 
          });
        }
      }
    } catch (e) {
      // Fallback Demo Mode
      if (mounted) {
        setState(() {
          _temp = "30";
          _cityName = "Demo City";
          _weatherDesc = "Sunny";
          _humidity = "60";
          _weatherIconCode = "01d";
          _isLoadingWeather = false;
        });
      }
    }
  }

  // --- 5. POPUP CUSTOM ---
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
                decoration: const BoxDecoration(
                  color: Color(0xFF4B6EF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Enable Location", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                "Please activate the location feature,\nso we can find your home address.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    LocationPermission permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                      _fetchWeatherData();
                    } else {
                      setState(() { _cityName = "Denied"; _isLoadingWeather = false; });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B6EF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text("Enable Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() { _cityName = "N/A"; _isLoadingWeather = false; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FA),
                    foregroundColor: const Color(0xFF4B6EF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text("Not Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea giữ lại để nội dung không bị tai thỏ che mất
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildWeatherCard(),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("All Devices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Icon(Icons.more_vert, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 16),
              
              // LIST ROOM NGANG (Sẽ tự động cập nhật khi load xong Service)
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
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
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
              _buildEmptyState(primaryColor),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // --- ĐÃ XÓA BOTTOM NAV BAR VÀ FAB ---
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
              child: Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none, color: Colors.black87),
            ),
          ],
        )
      ],
    );
  }

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
                  decoration: BoxDecoration(
                    color: Colors.grey[100], borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
              Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 90, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: const Center(child: Icon(Icons.paste_rounded, size: 40, color: Colors.blueAccent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("No Devices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("You haven't added a device yet.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 24),
          // Nếu vợ muốn giữ nút Add ở đây (trong nội dung) thì để lại, còn không thì xóa luôn nhé.
          // Chồng giữ lại vì nó nằm trong nội dung trang, không phải floating button.
          SizedBox(
            width: 180, height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                 Navigator.pushNamed(context, AppRoutes.addDevice);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4, shadowColor: primaryColor.withOpacity(0.4),
              ),
            ),
          )
        ],
      ),
    );
  }
}