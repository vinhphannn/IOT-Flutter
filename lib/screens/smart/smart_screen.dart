import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/smart_provider.dart';
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

class _SmartScreenState extends State<SmartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load dữ liệu lần đầu tiên khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    final houseProvider = context.read<HouseProvider>();
    final smartProvider = context.read<SmartProvider>();

    // 1. Nếu chưa có danh sách nhà -> Tải nhà trước
    if (houseProvider.houses.isEmpty) {
      houseProvider.fetchHouses().then((_) {
        // Tải xong nhà thì tải Scene cho nhà mặc định
        if (houseProvider.currentHouse != null) {
          smartProvider.fetchScenes(houseProvider.currentHouse!.id);
        }
      });
    } 
    // 2. Nếu đã có nhà -> Tải Scene luôn
    else if (houseProvider.currentHouse != null) {
      smartProvider.fetchScenes(houseProvider.currentHouse!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Lắng nghe sự thay đổi của HouseID
    final houseId = context.select<HouseProvider, int?>((p) => p.currentHouse?.id);

    // LOGIC TỰ ĐỘNG RELOAD KHI ĐỔI NHÀ
    // Dùng addPostFrameCallback để tránh lỗi setState trong lúc build
    if (houseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final smartProvider = context.read<SmartProvider>();
        // Nếu danh sách hiện tại rỗng HOẶC danh sách đang hiển thị không phải của nhà này (check logic sâu hơn nếu cần)
        // Ở đây chồng cho load lại nếu danh sách rỗng để đảm bảo data
        if (smartProvider.scenes.isEmpty && !smartProvider.isLoading) {
           smartProvider.fetchScenes(houseId);
        }
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
                        icon: const Icon(Icons.description_outlined, color: Colors.black87),
                        onPressed: () {},
                      ),
                      // Nút mở trang Quản lý (Xóa)
                      IconButton(
                        icon: const Icon(Icons.grid_view, color: Colors.black87),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageScenesScreen()),
                          ).then((_) {
                            // Khi quay lại từ trang quản lý, reload lại list cho chắc
                            if (houseId != null) {
                              context.read<SmartProvider>().fetchScenes(houseId);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. TAB BAR
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: "Automation"),
                    Tab(text: "Tap-to-Run"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. CONTENT (LIST SCENES)
            Expanded(
              child: houseId == null
                  ? const Center(child: Text("Please create or join a home"))
                  : Consumer<SmartProvider>(
                      builder: (context, smartProvider, child) {
                        if (smartProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // Automation Tab
                            AutomationTab(scenes: smartProvider.automationScenes),
                            // Tap-to-Run Tab
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
        onPressed: () async {
          // Chờ kết quả từ trang tạo
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSceneScreen()),
          );
          
          // Tạo xong quay về thì reload lại list
          if (houseId != null && context.mounted) {
             context.read<SmartProvider>().fetchScenes(houseId);
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}