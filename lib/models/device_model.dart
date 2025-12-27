import 'package:flutter/material.dart';

class Device {
  final int id;
  final String name;
  final String macAddress;
  final String type;
  bool isOn;
  final String roomName; // Đảm bảo tên biến là roomName

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.type,
    required this.isOn,
    required this.roomName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Thiết bị không tên",
      macAddress: json['macAddress'] ?? "",
      type: json['type'] ?? "UNKNOWN",
      isOn: json['status'] ?? false,
      roomName: json['room'] != null ? json['room']['name'] : "Chưa có phòng",
    );
  }

  // --- ĐÂY LÀ PHẦN SỬA LỖI "isSwitchable" ---
  bool get isSwitchable => type == 'RELAY' || type == 'SOCKET' || type == 'FAN';

  // --- ĐÂY LÀ PHẦN SỬA LỖI ICON ---
  IconData get icon {
    switch (type) {
      case 'RELAY': return Icons.lightbulb_outline;
      case 'SOCKET': return Icons.power;
      default: return Icons.devices_other;
    }
  }
}