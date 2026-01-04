import 'package:flutter/material.dart';

class Scene {
  final int id;
  final String name;
  final String type; // "AUTOMATION" hoặc "TAP_TO_RUN"
  final String iconUrl;
  final String colorCode;
  bool enabled;
  final int actionCount; // Số lượng hành động
  final String? description;

  Scene({
    required this.id,
    required this.name,
    required this.type,
    required this.iconUrl,
    required this.colorCode,
    required this.enabled,
    this.actionCount = 0,
    this.description,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    // Logic đếm số lượng task thông minh hơn
    int count = 0;
    
    // Ưu tiên 1: Nếu Backend trả về mảng 'actions', đếm độ dài mảng này
    if (json['actions'] != null && json['actions'] is List) {
      count = (json['actions'] as List).length;
    } 
    // Ưu tiên 2: Nếu Backend đã đếm sẵn và trả về field 'actionCount'
    else if (json['actionCount'] != null) {
      count = json['actionCount'];
    }

    return Scene(
      id: json['id'],
      name: json['name'] ?? "No Name",
      type: json['type'] ?? "TAP_TO_RUN",
      iconUrl: json['iconUrl'] ?? "default",
      colorCode: json['colorCode'] ?? "#000000",
      enabled: json['enabled'] ?? true,
      actionCount: count, // Dùng biến count đã tính ở trên
      description: json['description'],
    );
  }

  Color get color {
    try {
      String hex = colorCode.replaceAll("#", "");
      if (hex.length == 6) hex = "FF$hex";
      return Color(int.parse("0x$hex"));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData get iconData {
    // Mapping icon xịn hơn một chút
    if (iconUrl.contains("moon") || name.toLowerCase().contains("ngủ") || name.toLowerCase().contains("bed")) return Icons.bedtime;
    if (iconUrl.contains("sun") || name.toLowerCase().contains("sáng") || name.toLowerCase().contains("morning")) return Icons.wb_sunny;
    if (iconUrl.contains("clock") || type == "AUTOMATION") return Icons.access_time_filled;
    if (iconUrl.contains("touch") || type == "TAP_TO_RUN") return Icons.touch_app;
    return Icons.smart_button;
  }
}