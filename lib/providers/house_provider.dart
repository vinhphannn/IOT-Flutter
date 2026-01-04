import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/house_model.dart';
import '../services/house_service.dart';

class HouseProvider extends ChangeNotifier {
  final HouseService _houseService = HouseService();
  
  List<House> _houses = [];
  House? _currentHouse;
  bool _isLoading = false;

  List<House> get houses => _houses;
  House? get currentHouse => _currentHouse;
  bool get isLoading => _isLoading;

  // --- 1. LẤY DANH SÁCH NHÀ & KHÔI PHỤC NHÀ ĐÃ CHỌN ---
  Future<void> fetchHouses() async {
    _isLoading = true;
    notifyListeners(); // Báo UI hiện loading

    try {
      _houses = await _houseService.fetchMyHouses();
      
      // Lấy lại ID nhà đã lưu lần trước
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? savedHouseId = prefs.getInt('currentHouseId');

      if (_houses.isNotEmpty) {
        if (savedHouseId != null) {
          // Tìm nhà có ID trùng khớp, nếu không thấy thì lấy nhà đầu tiên
          _currentHouse = _houses.firstWhere(
            (h) => h.id == savedHouseId, 
            orElse: () => _houses[0]
          );
        } else {
          _currentHouse = _houses[0];
        }
        // Lưu lại để chắc chắn
        await prefs.setInt('currentHouseId', _currentHouse!.id);
      }
    } catch (e) {
      debugPrint("Lỗi HouseProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Báo UI cập nhật dữ liệu mới
    }
  }

  // --- 2. CHỌN NHÀ MỚI ---
  Future<void> selectHouse(House house) async {
    if (_currentHouse?.id == house.id) return;

    _currentHouse = house;
    
    // Lưu vào máy
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentHouseId', house.id);

    notifyListeners(); // Báo cho TẤT CẢ màn hình biết để load lại thiết bị/smart
  }
}