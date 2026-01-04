import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/house_provider.dart';
import '../../widgets/house_selector_dropdown.dart'; // Import widget dùng chung
import 'tabs/automation_tab.dart';
import 'tabs/tap_to_run_tab.dart';

class SmartScreen extends StatefulWidget {
  const SmartScreen({super.key});

  @override
  State<SmartScreen> createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Đảm bảo danh sách nhà được tải nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final houseProvider = context.read<HouseProvider>();
      if (houseProvider.houses.isEmpty) {
        houseProvider.fetchHouses();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👇 SỬ DỤNG WIDGET DÙNG CHUNG CHO DROPDOWN NHÀ
                  const Expanded(child: HouseSelectorDropdown()),
                  
                  // Icon bên phải
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.description_outlined, color: Colors.black87),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.grid_view, color: Colors.black87),
                        onPressed: () {},
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 2. TAB BAR
     // 2. CUSTOM TAB BAR (ĐÃ SỬA LẠI ĐẸP HƠN)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white, // Màu nền trắng cho cả thanh Tab
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0), // Padding nhỏ để indicator không chạm viền
                child: TabBar(
                  controller: _tabController,
                  
                  // --- CẤU HÌNH INDICATOR ĐỂ BỌC HẾT ---
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10), // Bo góc cho phần xanh
                    color: primaryColor, // Màu xanh chủ đạo
                  ),
                  indicatorSize: TabBarIndicatorSize.tab, // Quan trọng: Bắt buộc indicator giãn full tab
                  dividerColor: Colors.transparent, // Xóa gạch chân mặc định
                  
                  // --- MÀU CHỮ ---
                  labelColor: Colors.white, // Chữ khi được chọn
                  unselectedLabelColor: Colors.grey[600], // Chữ khi chưa chọn
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  
                  tabs: const [
                    Tab(text: "Automation"),
                    Tab(text: "Tap-to-Run"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. CONTENT (LẮNG NGHE HOUSE PROVIDER)
            Expanded(
              child: Consumer<HouseProvider>(
                builder: (context, houseProvider, child) {
                  final currentHouseId = houseProvider.currentHouse?.id;

                  if (houseProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (currentHouseId == null) {
                    return const Center(child: Text("Please create or join a home"));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Truyền houseId vào để Tab tự load API Automation của nhà đó
                      AutomationTab(houseId: currentHouseId), 
                      TapToRunTab(houseId: currentHouseId),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 4. FLOATING ACTION BUTTON (+)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mở trang thêm automation/tap-to-run tương ứng với tab đang chọn
          if (_tabController.index == 0) {
             // Navigator.pushNamed(context, '/add-automation');
          } else {
             // Navigator.pushNamed(context, '/add-tap-to-run');
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}