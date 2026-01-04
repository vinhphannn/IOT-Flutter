import 'package:flutter/material.dart';
import '../models/scene_model.dart';
import '../services/smart_service.dart';

class SmartProvider extends ChangeNotifier {
  final SmartService _service = SmartService();
  
  List<Scene> _scenes = [];
  bool _isLoading = false;

  List<Scene> get scenes => _scenes;
  bool get isLoading => _isLoading;

  // Lọc danh sách cho UI
  List<Scene> get automationScenes => _scenes.where((s) => s.type == 'AUTOMATION').toList();
  List<Scene> get tapToRunScenes => _scenes.where((s) => s.type == 'TAP_TO_RUN').toList();

  // 1. Tải dữ liệu
  Future<void> fetchScenes(int houseId) async {
    _isLoading = true;
    notifyListeners();

    _scenes = await _service.getScenes(houseId);
    
    _isLoading = false;
    notifyListeners();
  }

  // 2. Chạy kịch bản (Tap-to-Run)
  Future<void> executeScene(int sceneId) async {
    await _service.executeScene(sceneId);
    // Có thể hiện thông báo thành công ở UI
  }

  // 3. Bật/Tắt Automation (Optimistic UI update)
  Future<void> toggleAutomation(int sceneId, bool currentValue) async {
    // Cập nhật UI ngay lập tức cho mượt
    final index = _scenes.indexWhere((s) => s.id == sceneId);
    if (index != -1) {
      _scenes[index].enabled = !currentValue;
      notifyListeners();
    }

    // Gọi API
    bool success = await _service.toggleScene(sceneId);

    // Nếu lỗi thì rollback lại trạng thái cũ
    if (!success && index != -1) {
      _scenes[index].enabled = currentValue;
      notifyListeners();
    }
  }
  Future<bool> deleteScene(int sceneId) async {
    // Gọi API
    bool success = await _service.deleteScene(sceneId);

    if (success) {
      // Xóa thành công -> Loại bỏ khỏi danh sách local ngay để UI cập nhật
      _scenes.removeWhere((s) => s.id == sceneId);
      notifyListeners();
    }
    return success;
  }
}