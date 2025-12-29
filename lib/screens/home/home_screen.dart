import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes.dart';
import '../../services/room_service.dart';
import '../../services/house_service.dart';
import '../../models/device_model.dart';
import '../../models/house_model.dart';
import '../../providers/device_provider.dart'; // 2. Import Kho tổng

import '../device/category_devices_screen.dart';
import 'home_weather_widget.dart';
import 'home_devices_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- BIẾN QUẢN LÝ NHÀ & DỮ LIỆU ---
  List<House> _houses = [];
  House? _currentHouse;
  bool _isLoadingHouse = true;

  int _selectedRoomIndex = 0;
  List<String> _rooms = ["All Rooms"];
  
  // Vợ ơi, mình bỏ _allDevices và _homeDisplayDevices cục bộ đi nhé
  // Vì giờ mình dùng hàng xịn từ Provider rồi!

  @override
  void initState() {
    super.initState();
    _initHomeData();
  }

  // --- LOGIC DỮ LIỆU (NHÀ, PHÒNG, THIẾT BỊ) ---
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
         if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginOptions, (route) => false);
      }
    }
  }

  Future<void> _fetchRoomsAndDevices(int houseId) async {
    final houseService = HouseService();
    final roomService = RoomService();

    List<String> roomsFromDb = [];
    List<Device> devicesFromDb = [];

    // Gọi API lấy dữ liệu
    try {
      roomsFromDb = await roomService.fetchRoomNamesByHouse(houseId);
    } catch (e) { debugPrint("❌ Lỗi lấy phòng: $e"); }

    try {
      devicesFromDb = await houseService.fetchDevicesByHouseId(houseId);
    } catch (e) { debugPrint("❌ Lỗi lấy thiết bị: $e"); }

    if (mounted) {
      setState(() {
        _rooms = ["All Rooms", ...roomsFromDb];
        _selectedRoomIndex = 0;
      });

      // --- 3. QUAN TRỌNG: NẠP DỮ LIỆU VÀO KHO TỔNG (PROVIDER) ---
      // Dòng này giúp fix lỗi ID=0 ở các trang sau
      context.read<DeviceProvider>().setDevices(devicesFromDb);
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

  // Hàm điều hướng giữ nguyên
  void _navigateToCategory(String type, String title) {
    // Lưu ý: Nếu cần truyền danh sách thiết bị vào Category, 
    // vợ có thể lấy từ Provider.of<DeviceProvider>(context, listen: false).devices
    final allDevices = context.read<DeviceProvider>().devices;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDevicesScreen(
          categoryType: type, title: title, allDevices: allDevices,
        ),
      ),
    );
  }

  // --- GIAO DIỆN CHÍNH (Đã nâng cấp Consumer) ---
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

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
                // 1. Header (Chọn nhà & Icon)
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // 2. Weather Widget
                const HomeWeatherWidget(),
                const SizedBox(height: 24),

                // 3. Devices Body - BỌC TRONG CONSUMER ĐỂ TỰ CẬP NHẬT
                Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, child) {
                    // Lấy dữ liệu từ Kho tổng
                    final allDevices = deviceProvider.devices;
                    
                    // Logic lọc thiết bị theo phòng (đưa từ hàm cũ vào đây)
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
                      onRoomChanged: (index) {
                        setState(() {
                          _selectedRoomIndex = index;
                          // Không cần gọi _filterDevices nữa vì Consumer sẽ tự lo
                        });
                      },
                      onCategoryTap: _navigateToCategory,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header vẫn giữ nguyên
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
                  Icon(Icons.home, color: h.id == _currentHouse?.id ? Theme.of(context).primaryColor : Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Text(h.name, style: TextStyle(fontWeight: h.id == _currentHouse?.id ? FontWeight.bold : FontWeight.normal)),
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
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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