// lib/models/device_item_model.dart
import 'package:flutter/material.dart';

class DeviceItem {
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final String macAddress;

  DeviceItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.macAddress = "",
  });
}