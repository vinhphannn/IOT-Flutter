import 'package:flutter/material.dart';
import '../../routes.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // Quản lý trang hiện tại (0, 1, 2, 3)
  int _currentStep = 0;
  final int _totalSteps = 4;
  final PageController _pageController = PageController();

  // DỮ LIỆU CỦA NGƯỜI DÙNG
  String? _selectedCountry;
  final TextEditingController _homeNameController = TextEditingController();
  final List<String> _selectedRooms = [];

  // --- PHẦN TÌM KIẾM QUỐC GIA ---
  // Controller cho ô tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  
  // Danh sách gốc (Database)
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

  // Danh sách hiển thị (Sẽ thay đổi khi tìm kiếm)
  List<Map<String, String>> _filteredCountries = [];

  // Danh sách cứng cho Step 3 (Phòng)
  final List<String> _rooms = [
    "Living Room", "Bedroom", "Bathroom", "Kitchen", 
    "Study Room", "Dining Room", "Backyard", "Garage"
  ];

  @override
  void initState() {
    super.initState();
    // Ban đầu danh sách hiển thị = danh sách gốc
    _filteredCountries = _countries; 
  }

  // Hàm lọc quốc gia
  void _runFilter(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      // Nếu không nhập gì thì hiện hết
      results = _countries;
    } else {
      // Lọc theo tên (chuyển về chữ thường để so sánh không phân biệt hoa thường)
      results = _countries
          .where((country) =>
              country["name"]!.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    // Cập nhật giao diện
    setState(() {
      _filteredCountries = results;
    });
  }

  // Hàm chuyển trang tiếp theo
  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    }
  }

  // Hàm quay lại
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
                _buildStep1Country(), // Đã cập nhật tìm kiếm
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

  // --- STEP 1: CHỌN QUỐC GIA (ĐÃ THÊM TÌM KIẾM) ---
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
              style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Inter'
              ),
              children: [
                TextSpan(
                  text: "Country",
                  style: TextStyle(color: primaryColor),
                ),
                const TextSpan(
                  text: " of Origin",
                  style: TextStyle(color: Colors.black),
                ),
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
          
          // --- Ô TÌM KIẾM (ĐÃ NỐI LOGIC) ---
          TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value), // Gọi hàm lọc mỗi khi gõ
            decoration: InputDecoration(
              hintText: "Search Country...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          
          // --- DANH SÁCH QUỐC GIA (HIỂN THỊ LIST ĐÃ LỌC) ---
          Expanded(
            child: _filteredCountries.isNotEmpty 
            ? ListView.separated(
              itemCount: _filteredCountries.length, // Dùng list đã lọc
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _selectedCountry == country['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCountry = country['name'];
                      // Xóa tìm kiếm sau khi chọn xong cho gọn (tuỳ bạn)
                      // _searchController.clear();
                      // _runFilter('');
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade200,
                        width: 1.5
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle
                          ),
                          child: Text(country['flag']!, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          country['name']!, 
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87
                          )
                        ),
                        const Spacer(),
                        if (isSelected)
                           Icon(Icons.check_circle, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            )
            : const Center( // Nếu không tìm thấy kết quả
                child: Text("No country found", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: ĐẶT TÊN NHÀ ---
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
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
                final isSelected = _selectedRooms.contains(room);
                final primaryColor = Theme.of(context).primaryColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedRooms.remove(room) : _selectedRooms.add(room);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [
                        BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 32, color: isSelected ? Colors.white : Colors.grey[600]),
                        const SizedBox(height: 10),
                        Text(room, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                        if (isSelected) const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.check_circle, color: Colors.white, size: 16))
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

  // --- STEP 4: VỊ TRÍ (MAP) ---
  Widget _buildStep4Location() {
    return Stack(
      children: [
        Container(width: double.infinity, height: double.infinity, color: Colors.grey[200], child: const Center(child: Icon(Icons.map, size: 100, color: Colors.grey))),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Colors.white.withOpacity(0)])
            ),
            child: _buildHeader("Set Home Location", "Pin your home's location to enhance location-based features."),
          ),
        ),
        const Center(child: Icon(Icons.location_on, size: 50, color: Colors.red)),
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
             ),
             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Address Details", style: TextStyle(color: Colors.grey)), const SizedBox(height: 5), const Text("701 7th Ave, New York, 10036, USA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          ),
        )
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
      ],
    );
  }
}