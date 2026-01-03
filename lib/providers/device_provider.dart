import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../models/device_model.dart';
import '../services/house_service.dart';
import '../services/api_client.dart'; // Thêm ApiClient để gọi API lấy danh sách

class DeviceProvider extends ChangeNotifier {
  // --- KHO DỮ LIỆU ---
  List<Device> _devices = [];
  StompClient? _stompClient;
  bool _isLoading = false;

  // Getter
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;

  // --- 1. QUAN TRỌNG: HÀM TẢI DANH SÁCH TỪ SERVER ---
  Future<void> fetchDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vợ thay đường dẫn API này cho đúng với Backend của vợ
      // Ví dụ: Lấy tất cả thiết bị của User hoặc của Nhà đang chọn
      final response = await ApiClient.get('/devices/public/all'); 
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _devices = data.map((json) => Device.fromJson(json)).toList();
        
        // Sau khi có danh sách -> Kết nối Socket ngay để nghe ngóng
        _initWebSocket();
      } else {
        print("❌ Lỗi tải thiết bị: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi mạng khi tải thiết bị: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. HÀM NẠP DANH SÁCH (Dùng khi Login xong hoặc chuyển nhà) ---
  void setDevices(List<Device> devices) {
    _devices = devices;
    notifyListeners();
    
    // Nếu chưa kết nối Socket thì kết nối ngay
    if (_stompClient == null || !_stompClient!.connected) {
      _initWebSocket();
    } else {
      // Nếu đã kết nối rồi thì đăng ký lại cho danh sách mới
      _subscribeAllDevices();
    }
  }

  // --- 3. KHỞI TẠO WEBSOCKET ---
  void _initWebSocket() {
    // Nếu đang kết nối rồi thì thôi
    if (_stompClient != null && _stompClient!.connected) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: AppConfig.webSocketUrl, 
        onConnect: _onConnect,
        onStompError: (frame) => print("❌ Stomp Error: ${frame.body}"),
        webSocketConnectHeaders: {"transports": ["websocket"]},
        // Tự động kết nối lại sau 5 giây nếu rớt mạng
        reconnectDelay: const Duration(seconds: 5), 
      ),
    );
    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    print("✅ WebSocket Global Connected!");
    _subscribeAllDevices();
  }

  // Tách hàm Subscribe riêng để tái sử dụng
  void _subscribeAllDevices() {
    if (_stompClient == null || !_stompClient!.connected) return;

    for (var device in _devices) {
      final macUpper = device.macAddress.toUpperCase();
      
      _stompClient!.subscribe(
        destination: '/topic/device/$macUpper/data',
        callback: (frame) {
          if (frame.body != null) {
            _updateDeviceFromSocket(device.id, frame.body!);
          }
        },
      );
    }
  }

  // --- 4. XỬ LÝ DỮ LIỆU SOCKET ---
  void _updateDeviceFromSocket(int deviceId, String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      
      final index = _devices.indexWhere((d) => d.id == deviceId);
      
      if (index != -1) {
        final device = _devices[index];

        // A. XỬ LÝ KẾT NỐI
        if (data.containsKey('online')) {
          bool isOnline = data['online'];
          
          // Chỉ cập nhật và vẽ lại nếu trạng thái THỰC SỰ thay đổi
          if (device.isOnline != isOnline) {
             device.isOnline = isOnline;
             if (!isOnline) device.isOn = false; // Mất mạng -> Tắt
             notifyListeners();
          }
        }

        // B. XỬ LÝ TRẠNG THÁI (ON/OFF)
        if (data.containsKey('status')) {
          bool newStatus = data['status'];
          if (device.isOn != newStatus) {
            device.isOn = newStatus;
            notifyListeners();
          }
        }

        // C. XỬ LÝ CHỈ SỐ
        bool hasDataChange = false;
        if (data.containsKey('p')) {
          double newPower = double.tryParse(data['p'].toString()) ?? 0.0;
          if (device.power != newPower) {
            device.power = newPower;
            hasDataChange = true;
          }
        }
        if (data.containsKey('i')) {
          double newCurrent = double.tryParse(data['i'].toString()) ?? 0.0;
          if (device.current != newCurrent) {
            device.current = newCurrent;
            hasDataChange = true;
          }
        }
        if (data.containsKey('totalKwh')) {
          double newKwh = double.tryParse(data['totalKwh'].toString()) ?? 0.0;
          if (device.totalKwh != newKwh) {
            device.totalKwh = newKwh;
            hasDataChange = true;
          }
        }

        if (hasDataChange) notifyListeners();
      }
    } catch (e) {
      print("⚠️ Lỗi update socket: $e");
    }
  }

  // --- 5. ĐIỀU KHIỂN THIẾT BỊ ---
  Future<void> toggleDevice(int deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final device = _devices[index];
    
    if (!device.isOnline) {
      print("🚫 Thiết bị đang Offline, từ chối điều khiển.");
      return; 
    }

    // Optimistic UI
    device.isOn = !device.isOn;
    notifyListeners();

    try {
      // Gọi API Backend
      bool success = await HouseService().toggleDevice(
        device.id.toString(), 
        device.isOn
      );
      
      if (!success) {
        device.isOn = !device.isOn; // Rollback
        notifyListeners();
      }
    } catch (e) {
      print("❌ Lỗi toggle: $e");
      device.isOn = !device.isOn; // Rollback
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }
}