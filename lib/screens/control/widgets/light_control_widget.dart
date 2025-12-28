import 'package:flutter/material.dart';
import '../../../models/device_model.dart';
import '../bodies/light_control_body.dart'; // Sử dụng lại cái vòng tròn màu vợ gửi

class LightControlWidget extends StatelessWidget {
  final Device device;
  const LightControlWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // Chồng tận dụng luôn file LightControlBody mà vợ đã có
    return const LightControlBody(); 
  }
}