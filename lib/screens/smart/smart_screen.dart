import 'package:flutter/material.dart';
import 'tabs/automation_tab.dart';
// import 'tabs/tap_to_run_tab.dart'; // Vợ tạo file này tương tự automation_tab nhé

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
      backgroundColor: const Color(0xFFF8F9FD), // Màu nền xám nhạt
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Tái sử dụng style của Home)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dropdown chọn nhà (Làm giao diện tĩnh trước, logic copy từ Home sau)
                  const Row(
                    children: [
                      Text("My Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, size: 28),
                    ],
                  ),
                  
                  // 2 Icon bên phải (Note & Grid)
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

            // 2. CUSTOM TAB BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primaryColor, // Màu xanh khi chọn
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: "Automation"),
                  Tab(text: "Tap-to-Run"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. TAB CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AutomationTab(),
                  // TapToRunTab(), // Tạm thời dùng AutomationTab cho cả 2 để test
                  AutomationTab(), 
                ],
              ),
            ),
          ],
        ),
      ),

      // 4. FLOATING ACTION BUTTON (+)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mở trang thêm automation
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}