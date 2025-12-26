import 'package:flutter/material.dart';

class Device {
  final String id;
  final String name;
  final String type; // 'Light', 'Camera', 'Speaker', 'AC', 'Router', 'Electrical'
  final IconData icon;
  final bool isWiFi;
  bool isOn;
  final String room;
  final String? imagePath; // Nếu có ảnh thật

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.isWiFi,
    this.isOn = false,
    required this.room,
    this.imagePath,
  });
}

// Dữ liệu mẫu dùng chung cho toàn App
final List<Device> demoDevices = [
  Device(id: '1', name: "Smart Lamp", type: "Light", icon: Icons.lightbulb_outline, isWiFi: true, isOn: true, room: "Living Room"),
  Device(id: '2', name: "Lamp", type: "Light", icon: Icons.lightbulb, isWiFi: true, isOn: true, room: "Bedroom"),
  Device(id: '3', name: "Smart Lamp", type: "Light", icon: Icons.lightbulb_outline, isWiFi: true, isOn: false, room: "Bedroom"),
  Device(id: '4', name: "Stereo Speaker", type: "Speaker", icon: Icons.speaker, isWiFi: false, isOn: true, room: "Living Room"),
  Device(id: '5', name: "Router", type: "Router", icon: Icons.router, isWiFi: true, isOn: true, room: "Living Room"),
  Device(id: '6', name: "Air Conditioner", type: "AC", icon: Icons.ac_unit, isWiFi: false, isOn: true, room: "Bedroom"),
  Device(id: '7', name: "Smart Webcam", type: "Camera", icon: Icons.videocam_outlined, isWiFi: true, isOn: false, room: "Bedroom"),
  Device(id: '8', name: "Smart V2 CCTV", type: "Camera", icon: Icons.video_camera_front_outlined, isWiFi: true, isOn: false, room: "Living Room", imagePath: 'assets/cctv1.png'),
  Device(id: '9', name: "Smart V3 CCTV", type: "Camera", icon: Icons.video_camera_back_outlined, isWiFi: true, isOn: false, room: "Kitchen"),
  Device(id: '10', name: "Smart Lamp", type: "Light", icon: Icons.lightbulb, isWiFi: true, isOn: true, room: "Kitchen"),
  Device(id: '11', name: "Lamp", type: "Light", icon: Icons.lightbulb_outline, isWiFi: true, isOn: false, room: "Bathroom"),
  Device(id: '12', name: "Smart Lamp", type: "Light", icon: Icons.lightbulb, isWiFi: true, isOn: true, room: "Toilet"),
];