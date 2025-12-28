import 'package:flutter/material.dart';

class Device {
  final int id;
  final String name;
  final String macAddress;
  final String type;      // Loại: RELAY, SOCKET, SENSOR...
  bool isOn;              // Trạng thái Bật/Tắt
  final String roomName;  // Tên phòng
  final bool isWiFi;      // (MỚI) Loại kết nối

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.type,
    required this.isOn,
    required this.roomName,
    this.isWiFi = true,   // Mặc định là Wifi
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Thiết bị không tên",
      macAddress: json['macAddress'] ?? "",
      type: json['type'] ?? "UNKNOWN",
      
      // (NÂNG CẤP) Bắt cả trường hợp true/false lẫn "ON"/"OFF"
      isOn: json['status'] == true || json['status'].toString().toUpperCase() == 'ON',
      
      roomName: json['room'] != null ? json['room']['name'] : "Chưa có phòng",
      
      // (MỚI) Nếu backend chưa trả về field này thì mặc định là true (Wifi)
      isWiFi: json['connectivity'] == 'BLE' ? false : true, 
    );
  }

  // --- LOGIC XÁC ĐỊNH LOẠI ---
  // Cảm biến (SENSOR) thì không có nút bật tắt
  bool get isSwitchable => type != 'SENSOR';

  // --- LOGIC ICON XỊN XÒ ---
  IconData get icon {
    switch (type.toUpperCase()) {
      case 'RELAY': 
      case 'LIGHT':
        return Icons.lightbulb;
      case 'SOCKET': 
        return Icons.power;
      case 'FAN': 
        return Icons.mode_fan_off;
      case 'SENSOR': 
        return Icons.sensors; // (MỚI) Icon cảm biến
      case 'TV':
        return Icons.tv;
      default: 
        return Icons.devices_other;
    }
  }
}