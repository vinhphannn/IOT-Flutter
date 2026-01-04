import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/smart_provider.dart'; // Import Provider mới
import '../../widgets/house_selector_dropdown.dart';
import 'tabs/automation_tab.dart';
import 'tabs/tap_to_run_tab.dart';
import 'create_scene_screen.dart';
import 'manage_scenes_screen.dart';

class SmartScreen extends StatefulWidget {
  const SmartScreen({super.key});

  @override
  State<SmartScreen> createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load danh sách nhà nếu chưa có
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

    // Lắng nghe HouseID hiện tại
    final houseId = context.select<HouseProvider, int?>(
      (p) => p.currentHouse?.id,
    );

    // Logic Fetch Scene khi HouseID thay đổi
    if (houseId != null) {
      // Dùng Future.microtask để tránh lỗi gọi setState trong lúc build
      Future.microtask(() {
        // Chỉ fetch nếu danh sách đang rỗng hoặc cần thiết (tuỳ logic cache của vợ)
        // Ở đây chồng gọi luôn để đảm bảo data mới nhất khi đổi nhà
        context.read<SmartProvider>().fetchScenes(houseId);
      });
    }

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
                  const Expanded(child: HouseSelectorDropdown()),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.description_outlined,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.grid_view,
                          color: Colors.black87,
                        ),
                        // 👇 SỬA LẠI CHỖ NÀY
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageScenesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: primaryColor,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: "Automation"),
                    Tab(text: "Tap-to-Run"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. CONTENT
            Expanded(
              child: houseId == null
                  ? const Center(child: Text("Please create or join a home"))
                  : Consumer<SmartProvider>(
                      builder: (context, smartProvider, child) {
                        if (smartProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // Truyền danh sách Scene đã lọc vào các Tab
                            AutomationTab(
                              scenes: smartProvider.automationScenes,
                            ),
                            TapToRunTab(scenes: smartProvider.tapToRunScenes),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSceneScreen()),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
