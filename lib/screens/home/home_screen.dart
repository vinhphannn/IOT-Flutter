import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes.dart';
import '../../services/room_service.dart';
import '../../services/house_service.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/house_provider.dart'; // <--- Import Provider
import '../../widgets/house_selector_dropdown.dart'; // <--- Import Widget dùng chung

import '../device/category_devices_screen.dart';
import 'home_weather_widget.dart';
import 'home_devices_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedRoomIndex = 0;
  List<String> _rooms = ["All Rooms"];
  
  @override
  void initState() {
    super.initState();
    // Gọi Provider để lấy danh sách nhà ngay khi vào Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseProvider>().fetchHouses();
    });
  }

  // --- LẮNG NGHE SỰ THAY ĐỔI CỦA NHÀ ---
  // Mỗi khi HouseProvider đổi nhà, hàm này sẽ được gọi (thông qua Consumer hoặc didChangeDependencies)
  // Tuy nhiên, cách tốt nhất là dùng một hàm riêng để fetch data dựa trên houseId mới
  Future<void> _fetchRoomsAndDevices(int houseId) async {
    final houseService = HouseService();
    final roomService = RoomService();

    List<String> roomsFromDb = [];
    List<Device> devicesFromDb = [];

    try {
      final roomObjects = await roomService.fetchRoomsByHouse(houseId);
      roomsFromDb = roomObjects.map((r) => r.name).toList();
    } catch (e) { debugPrint("❌ Lỗi lấy phòng: $e"); }

    try {
      devicesFromDb = await houseService.fetchDevicesByHouseId(houseId);
    } catch (e) { debugPrint("❌ Lỗi lấy thiết bị: $e"); }

    if (mounted) {
      setState(() {
        _rooms = ["All Rooms", ...roomsFromDb];
        _selectedRoomIndex = 0; // Reset về All Rooms khi đổi nhà
      });
      context.read<DeviceProvider>().setDevices(devicesFromDb);
    }
  }

  void _navigateToCategory(String type, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDevicesScreen(categoryType: type, title: title)));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<HouseProvider>(
          builder: (context, houseProvider, child) {
            // --- LOGIC TỰ ĐỘNG TẢI LẠI DỮ LIỆU ---
            // Nếu nhà thay đổi và khác với nhà hiện tại đang hiển thị, hãy tải lại phòng/thiết bị
            // Lưu ý: Để tránh loop vô hạn, ta chỉ gọi hàm fetch nếu cần thiết. 
            // Tuy nhiên, trong Consumer build, ta không nên gọi async trực tiếp.
            // Cách đơn giản nhất: Dùng FutureBuilder hoặc gọi fetch ở đây nhưng cần cẩn thận.
            // Ở đây chồng dùng một trick nhỏ: Lấy ID nhà hiện tại, truyền vào FutureBuilder bên dưới hoặc 
            // đơn giản là cứ mỗi lần build lại (do notifyListeners), ta hiển thị dữ liệu mới.
            
            // Nhưng thiết bị và phòng đang nằm ở biến local (_rooms) và DeviceProvider.
            // Nên ta cần một cơ chế Trigger.
            // Giải pháp: Dùng `didUpdateWidget` hoặc so sánh ID cũ/mới.
            // Để đơn giản cho vợ, chồng sẽ gọi _fetchRoomsAndDevices ngay khi ID nhà thay đổi.
            
            // Tạm thời chồng sẽ gọi hàm fetch mỗi khi HouseProvider báo thay đổi (nhưng cần debounce để tránh spam).
            // Tốt nhất là dùng `Selector` hoặc check ID.
            
            // -> Chồng sẽ dùng `_CheckHouseChange` widget con để xử lý việc này cho gọn.
            return _CheckHouseChange(
              houseId: houseProvider.currentHouse?.id,
              onHouseChanged: (id) => _fetchRoomsAndDevices(id),
              child: RefreshIndicator(
                onRefresh: () async {
                  await houseProvider.fetchHouses();
                  if (houseProvider.currentHouse != null) {
                    await _fetchRoomsAndDevices(houseProvider.currentHouse!.id);
                  }
                },
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header (Dùng Widget dùng chung)
                      _buildHeader(context), 
                      const SizedBox(height: 24),
                      
                      // 2. Weather
                      const HomeWeatherWidget(),
                      const SizedBox(height: 24),

                      // 3. Devices Body
                      Consumer<DeviceProvider>(
                        builder: (context, deviceProvider, child) {
                          final allDevices = deviceProvider.devices;
                          List<Device> displayDevices;
                          if (_selectedRoomIndex == 0) {
                            displayDevices = allDevices;
                          } else {
                            String roomName = _rooms[_selectedRoomIndex];
                            displayDevices = allDevices.where((d) => d.roomName == roomName).toList();
                          }

                          return HomeDevicesBody(
                            allDevices: allDevices,
                            displayDevices: displayDevices,
                            rooms: _rooms,
                            selectedRoomIndex: _selectedRoomIndex,
                            onRoomChanged: (index) => setState(() => _selectedRoomIndex = index),
                            onCategoryTap: _navigateToCategory,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 👇 THAY THẾ BẰNG WIDGET DÙNG CHUNG
        const Expanded(child: HouseSelectorDropdown()), 
        
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
                    Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

// --- WIDGET PHỤ ĐỂ THEO DÕI SỰ THAY ĐỔI NHÀ ---
class _CheckHouseChange extends StatefulWidget {
  final int? houseId;
  final Function(int) onHouseChanged;
  final Widget child;

  const _CheckHouseChange({required this.houseId, required this.onHouseChanged, required this.child});

  @override
  State<_CheckHouseChange> createState() => _CheckHouseChangeState();
}

class _CheckHouseChangeState extends State<_CheckHouseChange> {
  @override
  void didUpdateWidget(covariant _CheckHouseChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu ID nhà thay đổi, gọi hàm fetch dữ liệu mới
    if (widget.houseId != null && widget.houseId != oldWidget.houseId) {
      widget.onHouseChanged(widget.houseId!);
    }
  }

  @override
  void initState() {
    super.initState();
    // Gọi lần đầu tiên
    if (widget.houseId != null) {
      widget.onHouseChanged(widget.houseId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}