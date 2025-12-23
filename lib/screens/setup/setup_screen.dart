import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../routes.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // --- 1. BIẾN QUẢN LÝ CHUNG ---
  int _currentStep = 0;
  final int _totalSteps = 4;
  final PageController _pageController = PageController();

  // Dữ liệu
  String? _selectedCountry;
  final TextEditingController _homeNameController = TextEditingController();
  final List<String> _selectedRooms = [];

  // --- 2. BIẾN STEP 1 ---
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _countries = [
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'Vietnam', 'flag': '🇻🇳'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'China', 'flag': '🇨🇳'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Australia', 'flag': '🇦🇺'},
  ];
  List<Map<String, String>> _filteredCountries = [];

  // --- 3. BIẾN STEP 3 ---
  final List<Map<String, String>> _rooms = [
    {"name": "Living Room", "icon": "assets/icons/living_room.png"},
    {"name": "Bedroom", "icon": "assets/icons/bedroom.png"},
    {"name": "Bathroom", "icon": "assets/icons/bathroom.png"},
    {"name": "Kitchen", "icon": "assets/icons/kitchen.png"},
    {"name": "Study Room", "icon": "assets/icons/study_room.png"},
    {"name": "Dining Room", "icon": "assets/icons/dining_room.png"},
    {"name": "Backyard", "icon": "assets/icons/backyard.png"},
    {"name": "Garage", "icon": "assets/icons/garage.png"},
  ];

  // --- 4. BIẾN STEP 4 (MAP) ---
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  LatLng _currentCenter = const LatLng(10.7769, 106.7009); // Mặc định HCM
  bool _isGettingAddress = false;

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
    _getAddressFromLatLng(_currentCenter);
  }

  // --- API LẤY ĐỊA CHỈ ---
  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (!mounted) return;
    setState(() {
      _isGettingAddress = true;
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'com.smartify.app/1.0' 
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name']; 
        
        if (mounted) {
          setState(() {
            // Lấy ngắn gọn lại cho đẹp (tuỳ chỉnh nếu muốn full)
            _addressController.text = address ?? "Unknown location";
          });
        }
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGettingAddress = false;
        });
      }
    }
  }

  // Filter
  void _runFilter(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _countries;
    } else {
      results = _countries
          .where((country) =>
              country["name"]!.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _filteredCountries = results;
    });
  }

  // Nav
  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.signUpComplete);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevPage,
        ),
        title: SizedBox(
          height: 12, 
          width: size.width * 0.65, 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[200], 
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 12, 
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                "${_currentStep + 1}/$_totalSteps",
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildStep1Country(),
                _buildStep2HomeName(),
                _buildStep3AddRooms(),
                _buildStep4Location(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Skip", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- STEP 1 ---
  Widget _buildStep1Country() {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "Select ",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Inter'),
              children: [
                TextSpan(text: "Country", style: TextStyle(color: primaryColor)),
                const TextSpan(text: " of Origin", style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Let's start by selecting the country where your smart haven resides.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value),
            decoration: InputDecoration(
              hintText: "Search Country...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredCountries.isNotEmpty 
            ? ListView.separated(
              itemCount: _filteredCountries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _selectedCountry == country['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCountry = country['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Text(country['flag']!, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 15),
                        Text(country['name']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const Spacer(),
                        if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            )
            : const Center(child: Text("No country found", style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  // --- STEP 2 ---
  Widget _buildStep2HomeName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader("Add Home Name", "Every smart home needs a name. What would you like to call yours?"),
          const SizedBox(height: 30),
          TextField(
            controller: _homeNameController,
            decoration: InputDecoration(
              hintText: "Enter Home Name (e.g. My Castle)",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3 ---
  Widget _buildStep3AddRooms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader("Add Rooms", "Select the rooms in your house. Don't worry, you can always add more later."),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 15, mainAxisSpacing: 15,
              ),
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final roomName = room['name']!;
                final roomIcon = room['icon']!;
                final isSelected = _selectedRooms.contains(roomName);
                final primaryColor = Theme.of(context).primaryColor;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedRooms.remove(roomName) : _selectedRooms.add(roomName);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          roomIcon,
                          width: 40, height: 40,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text(roomName, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                        if (isSelected) const Padding(padding: EdgeInsets.only(top: 8), child: Icon(Icons.check_circle, color: Colors.white, size: 18))
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: LOCATION (ĐÃ SỬA LẠI THEO THIẾT KẾ) ---
  Widget _buildStep4Location() {
    final primaryColor = Theme.of(context).primaryColor;
    
    // Sử dụng SingleChildScrollView + Column để bố trí dạng khối
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái cho tiêu đề
        children: [
          const SizedBox(height: 10),
          // 1. Header (Tiêu đề + Mô tả)
          _buildHeader("Set Home Location", 
              "Pin your home's location to enhance location-based features. Privacy is our priority."),
          
          const SizedBox(height: 30),

          // 2. KHUNG BẢN ĐỒ (VUÔNG/CHỮ NHẬT BO GÓC)
          Container(
            height: 400, // Chiều cao cố định cho đẹp (khoảng 50-60% màn hình)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), // Bo góc giống thiết kế
              // Nếu muốn có viền hoặc bóng đổ cho khung map thì thêm ở đây
              // color: Colors.grey[100], 
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24), // Cắt bản đồ theo góc bo
              child: Stack(
                children: [
                  // Lớp dưới: Bản đồ di chuyển được
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentCenter, 
                      initialZoom: 15.0,
                      onMapEvent: (MapEvent event) {
                        if (event is MapEventMoveEnd) {
                          _currentCenter = event.camera.center;
                          _getAddressFromLatLng(_currentCenter);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.smartify.app', 
                      ),
                    ],
                  ),

                  // Lớp trên: Cái ghim (Pin) nằm CỐ ĐỊNH CHÍNH GIỮA khung
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40), // Căn chỉnh mũi kim chạm đúng tâm
                      child: Icon(
                        Icons.location_on, 
                        size: 50, 
                        color: primaryColor // Màu xanh chủ đạo giống thiết kế (hoặc Colors.blue)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Address Details (Nhãn + Ô nhập liệu)
          const Text(
            "Address Details", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.black87
            )
          ),
          const SizedBox(height: 12),
          
          // Ô chứa địa chỉ (Nền xám nhạt)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50], // Nền xám nhạt giống thiết kế
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200), // Viền mỏng
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Move map to set location...",
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // Icon loading nhỏ nếu đang lấy địa chỉ
                if (_isGettingAddress)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else 
                  // Icon định vị nhỏ bên phải text
                  const Icon(Icons.my_location, color: Colors.grey, size: 20)
              ],
            ),
          ),
          
          const SizedBox(height: 20), // Khoảng trống dưới cùng
        ],
      ),
    );
  }

  // Widget Header chung
  Widget _buildHeader(String title, String subtitle) {
    // Tách riêng chữ "Location" tô màu xanh nếu cần, ở đây mình dùng RichText
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Set Home ",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Inter'),
            children: [
              TextSpan(text: "Location", style: TextStyle(color: Theme.of(context).primaryColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}