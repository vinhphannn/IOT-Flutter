import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/house_model.dart';
import '../services/house_service.dart';

class HouseProvider extends ChangeNotifier {
  final HouseService houseService = HouseService(); // Để public để dùng thủ công nếu cần
  
  List<House> _houses = [];
  House? _currentHouse;
  String? _currentRole; // Role của tôi trong nhà hiện tại
  bool _isLoading = false;

  List<House> get houses => _houses;
  House? get currentHouse => _currentHouse;
  String? get currentRole => _currentRole;
  bool get isLoading => _isLoading;

  // --- 1. LẤY DANH SÁCH NHÀ & ROLE ---
  Future<void> fetchHouses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _houses = await houseService.fetchMyHouses();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? savedHouseId = prefs.getInt('currentHouseId');

      if (_houses.isNotEmpty) {
        if (savedHouseId != null) {
          _currentHouse = _houses.firstWhere(
            (h) => h.id == savedHouseId, 
            orElse: () => _houses[0]
          );
        } else {
          _currentHouse = _houses[0];
        }
        // 👇 Quan trọng: Fetch luôn Role ngay khi load xong nhà
        await updateRoleForCurrentHouse();
      }
    } catch (e) {
      debugPrint("Lỗi HouseProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. CHỌN NHÀ MỚI & CẬP NHẬT ROLE ---
  Future<void> selectHouse(House house) async {
    if (_currentHouse?.id == house.id) return;
    _currentHouse = house;
    
    // Lưu vào máy
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentHouseId', house.id);

    // 👇 Cập nhật Role mới ngay lập tức
    await updateRoleForCurrentHouse();
    
    notifyListeners(); // Báo cho Home, Smart, Report load lại hết
  }

  // Hàm cập nhật Role riêng biệt
  Future<void> updateRoleForCurrentHouse() async {
    if (_currentHouse != null) {
      _currentRole = await houseService.fetchMyRoleInHouse(_currentHouse!.id);
      debugPrint("🔔 Đã cập nhật Role mới: $_currentRole cho nhà ${_currentHouse!.name}");
    }
  }
}