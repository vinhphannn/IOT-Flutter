import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../models/device_model.dart';
import '../services/house_service.dart'; // Hoặc DeviceService tùy vợ đang để hàm toggle ở đâu

class DeviceProvider extends ChangeNotifier {
  // --- KHO DỮ LIỆU ---
  List<Device> _devices = [];
  StompClient? _stompClient;

  // Getter để UI lấy dữ liệu
  List<Device> get devices => _devices;

  // 1. HÀM NẠP DANH SÁCH (Gọi từ Home Screen)
  void setDevices(List<Device> devices) {
    _devices = devices;
    notifyListeners(); // Vẽ lại giao diện ngay
    
    // Nếu chưa kết nối Socket thì kết nối ngay
    if (_stompClient == null || !_stompClient!.connected) {
      _initWebSocket();
    }
  }

  // 2. KHỞI TẠO WEBSOCKET (Kết nối 1 lần dùng mãi mãi)
  void _initWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: AppConfig.webSocketUrl, // ws://IP:8080/ws
        onConnect: _onConnect,
        onStompError: (frame) => print("❌ Stomp Error: ${frame.body}"),
        // Header quan trọng cho Android
        webSocketConnectHeaders: {"transports": ["websocket"]},
      ),
    );
    _stompClient!.activate();
  }

  // 3. ĐĂNG KÝ LẮNG NGHE (Subscribe)
  void _onConnect(StompFrame frame) {
    print("✅ WebSocket Global Connected!");
    
    // Duyệt qua tất cả thiết bị để lắng nghe Topic riêng của từng cái
    for (var device in _devices) {
      final macUpper = device.macAddress.toUpperCase();
      
      _stompClient!.subscribe(
        destination: '/topic/device/$macUpper/data',
        callback: (frame) {
          if (frame.body != null) {
            // Có tin nhắn -> Cập nhật kho -> Báo UI
            _updateDeviceFromSocket(device.id, frame.body!);
          }
        },
      );
    }
  }

  // 4. XỬ LÝ DỮ LIỆU SOCKET (Trái tim của Real-time)
  void _updateDeviceFromSocket(int deviceId, String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      
      // Tìm thiết bị trong kho
      final index = _devices.indexWhere((d) => d.id == deviceId);
      
      if (index != -1) {
        final device = _devices[index];

        // --- A. XỬ LÝ KẾT NỐI (QUAN TRỌNG) ---
        if (data.containsKey('online')) {
          device.isOnline = data['online'];
          
          // Logic tinh tế: Nếu mất mạng -> Tự động Tắt công tắc luôn
          if (device.isOnline == false) {
            device.isOn = false;
          }
        }

        // --- B. XỬ LÝ TRẠNG THÁI ---
        if (data.containsKey('status')) {
          device.isOn = data['status'];
        }

        // --- C. XỬ LÝ CHỈ SỐ (Parse an toàn tránh lỗi crash) ---
        if (data.containsKey('p')) {
          device.power = double.tryParse(data['p'].toString()) ?? 0.0;
        }
        if (data.containsKey('i')) {
          device.current = double.tryParse(data['i'].toString()) ?? 0.0;
        }
        if (data.containsKey('totalKwh')) {
          device.totalKwh = double.tryParse(data['totalKwh'].toString()) ?? 0.0;
        }

        // Hét lên cho cả App biết: "Dữ liệu mới về! Vẽ lại đi!"
        notifyListeners();
      }
    } catch (e) {
      print("⚠️ Lỗi update socket: $e");
    }
  }

  // 5. ĐIỀU KHIỂN THIẾT BỊ (Gọi từ UI)
  Future<void> toggleDevice(int deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final device = _devices[index];
    
    // CHẶN BẤM: Nếu đang Offline thì không cho làm gì cả
    if (!device.isOnline) {
      print("🚫 Thiết bị đang Offline, từ chối điều khiển.");
      return; 
    }

    // Optimistic UI: Cập nhật giao diện trước cho mượt (người dùng sướng)
    device.isOn = !device.isOn;
    notifyListeners();

    try {
      // Gọi API thực tế
      // Vợ chú ý: Nếu hàm toggleDevice nằm ở DeviceService thì đổi HouseService thành DeviceService nhé
      bool success = await HouseService().toggleDevice(
        device.id.toString(), 
        device.isOn
      );
      
      // Nếu API thất bại -> Hoàn tác lại trạng thái cũ (Rollback)
      if (!success) {
        device.isOn = !device.isOn;
        notifyListeners();
      }
    } catch (e) {
      // Lỗi mạng -> Cũng hoàn tác lại
      print("❌ Lỗi toggle: $e");
      device.isOn = !device.isOn;
      notifyListeners();
    }
  }

  // --- HÀM BỔ SUNG (CHO UI GỌI THỦ CÔNG) ---
  
  // Map để quản lý các gói đăng ký (để sau này còn hủy được)
  final Map<int, dynamic> _subscriptions = {};

  void subscribeToDevice(int deviceId) {
    // 1. Tìm thiết bị
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;
    
    final device = _devices[index];
    final macUpper = device.macAddress.toUpperCase();

    // 2. Kiểm tra kết nối
    if (_stompClient == null || !_stompClient!.connected) {
        print("⚠️ Socket chưa sẵn sàng, đang kết nối lại...");
        _initWebSocket();
        return;
    }

    print("🎧 [PROVIDER] Đang đăng ký lắng nghe: $macUpper");

    // 3. Đăng ký topic
    // Lưu cái token hủy vào Map để dùng sau này
    _subscriptions[deviceId] = _stompClient!.subscribe(
      destination: '/topic/device/$macUpper/data',
      callback: (frame) {
        if (frame.body != null) {
          _updateDeviceFromSocket(deviceId, frame.body!);
        }
      },
    );
  }

  // Hàm hủy đăng ký (Dùng khi thoát màn hình để đỡ tốn RAM)
  void unsubscribeFromDevice(int deviceId) {
    if (_subscriptions.containsKey(deviceId)) {
      _subscriptions[deviceId]?.call(); // Gọi hàm hủy
      _subscriptions.remove(deviceId);
      print("🔕 [PROVIDER] Đã hủy lắng nghe thiết bị $deviceId");
    }
  }

  // Ngắt kết nối khi thoát App hẳn (ít khi dùng nhưng nên có)
  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }
}