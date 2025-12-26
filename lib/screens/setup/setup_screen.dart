import 'dart:convert';
import 'dart:ui'; // Cần cho hiệu ứng Blur
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Bản đồ
import 'package:latlong2/latlong.dart';      // Tọa độ
import 'package:http/http.dart' as http;
import '../../routes.dart';
import '../../services/auth_service.dart'; // <--- Import Service

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
  bool _isLoading = false; 

  // Dữ liệu User nhập
  String? _selectedCountry;
  final TextEditingController _homeNameController = TextEditingController();
  final List<String> _selectedRooms = [];

  // --- 2. BIẾN STEP 1 (COUNTRY) ---
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _countries = [
    {'name': 'Vietnam', 'flag': '🇻🇳'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'China', 'flag': '🇨🇳'},
  ];
  List<Map<String, String>> _filteredCountries = [];

  // --- 3. BIẾN STEP 3 (ROOMS) ---
  // Lưu ý: Vợ nhớ check pubspec.yaml đã khai báo assets/icons/ chưa nhé
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
    // Lấy địa chỉ mặc định ban đầu
    _getAddressFromLatLng(_currentCenter);
  }

  // --- QUAN TRỌNG: HỦY CONTROLLER ĐỂ TRÁNH RÒ RỈ MEMORY ---
  @override
  void dispose() {
    _pageController.dispose();
    _homeNameController.dispose();
    _searchController.dispose();
    _addressController.dispose();
    // _mapController không cần dispose
    super.dispose();
  }

  // ==========================================
  // PHẦN 1: LOGIC XỬ LÝ (ACTION)
  // ==========================================

  // 1. Chuyển trang (Next)
  void _nextPage() {
    // Validate từng bước
    if (_currentStep == 0 && _selectedCountry == null) {
      _showError("Please select a country");
      return;
    }
    if (_currentStep == 1 && _homeNameController.text.trim().isEmpty) {
      _showError("Please enter your home name");
      return;
    }
    if (_currentStep == 2 && _selectedRooms.isEmpty) {
      _showError("Please select at least one room");
      return;
    }

    // Nếu chưa phải bước cuối -> Qua trang tiếp
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Nếu là bước cuối -> GỌI API SETUP
      _submitSetup();
    }
  }

  // 2. Quay lại (Back)
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

  // 3. Gửi dữ liệu về Backend
  void _submitSetup() async {
    setState(() => _isLoading = true);

    AuthService authService = AuthService();
    bool success = await authService.setupProfile(
      nationality: _selectedCountry ?? "Vietnam",
      houseName: _homeNameController.text,
      address: _addressController.text,
      roomNames: _selectedRooms,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Thành công -> Chuyển sang màn hình Hoàn tất hoặc Home
        // Ở đây chồng chuyển sang Home luôn hoặc trang Success tùy vợ config route
        Navigator.pushReplacementNamed(context, AppRoutes.home); 
      } else {
        _showError("Setup failed. Please check your connection.");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 4. API Lấy địa chỉ từ Tọa độ (OpenStreetMap)
  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (!mounted) return;
    setState(() => _isGettingAddress = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      // Thêm User-Agent để không bị block
      final response = await http.get(url, headers: {'User-Agent': 'com.smartify.app/1.0'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _addressController.text = data['display_name'] ?? "Unknown location";
          });
        }
      }
    } catch (e) {
      debugPrint("Error Map: $e");
    } finally {
      if (mounted) setState(() => _isGettingAddress = false);
    }
  }

  // 5. Lọc quốc gia
  void _runFilter(String enteredKeyword) {
    setState(() {
      if (enteredKeyword.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries
            .where((country) => country["name"]!.toLowerCase().contains(enteredKeyword.toLowerCase()))
            .toList();
      }
    });
  }

  // ==========================================
  // PHẦN 2: GIAO DIỆN (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // LỚP 1: UI CHÍNH
        Scaffold(
          backgroundColor: Colors.white,
          // --- APP BAR ---
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _prevPage,
            ),
            title: SizedBox(
              height: 8,
              width: size.width * 0.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 8,
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
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          
          // --- BODY ---
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Chặn vuốt tay, bắt buộc bấm nút
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildStep1Country(),
                    _buildStep2HomeName(),
                    _buildStep3AddRooms(),
                    _buildStep4Location(),
                  ],
                ),
              ),
              
              // --- BOTTOM BUTTONS ---
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Nút Skip (Ẩn ở bước cuối)
                    if (_currentStep < _totalSteps - 1)
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
                    
                    if (_currentStep < _totalSteps - 1)
                      const SizedBox(width: 20),

                    // Nút Continue / Finish
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
                          child: Text(
                            _currentStep == _totalSteps - 1 ? "Finish" : "Continue",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // LỚP 2: LOADING OVERLAY (Hiển thị khi đang gọi API)
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 20),
                        const Text("Creating your dream home...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // PHẦN 3: CÁC WIDGET CON (STEPS)
  // ==========================================

  // --- STEP 1: CHỌN QUỐC GIA ---
  Widget _buildStep1Country() {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          _buildHeader("Select Country of Origin", "Let's start by selecting the country where your smart haven resides."),
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
                        onTap: () => setState(() => _selectedCountry = country['name']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 15),
                              Text(country['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  // --- STEP 2: NHẬP TÊN NHÀ ---
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

  // --- STEP 3: CHỌN PHÒNG ---
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
                        // Dùng Image.asset và icon placeholder nếu lỗi
                        Image.asset(
                          roomIcon,
                          width: 40, height: 40,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.meeting_room, color: isSelected ? Colors.white : Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text(roomName, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
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

  // --- STEP 4: BẢN ĐỒ VỊ TRÍ ---
  Widget _buildStep4Location() {
    final primaryColor = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader("Set Home Location", "Pin your home's location to enhance location-based features."),
          const SizedBox(height: 30),

          // KHUNG BẢN ĐỒ
          Container(
            height: 400,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on, size: 50, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text("Address Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
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
                    ),
                  ),
                ),
                if (_isGettingAddress)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else 
                  const Icon(Icons.my_location, color: Colors.grey, size: 20)
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGET HEADER CHUNG (ĐÃ SỬA LỖI MÀU CHỮ) ---
  Widget _buildHeader(String title, String subtitle) {
    // Logic: Từ đầu tiên màu đen, các từ sau màu xanh chủ đạo
    List<String> words = title.split(' ');
    String firstWord = words.isNotEmpty ? "${words[0]} " : "";
    String restWords = words.length > 1 ? words.sublist(1).join(' ') : "";

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: firstWord,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Inter'),
            children: [
              TextSpan(text: restWords, style: TextStyle(color: Theme.of(context).primaryColor)),
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