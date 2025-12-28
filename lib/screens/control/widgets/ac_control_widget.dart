import 'package:flutter/material.dart';
import '../../../models/device_model.dart';

class ACControlWidget extends StatefulWidget {
  final Device device;
  const ACControlWidget({super.key, required this.device});

  @override
  State<ACControlWidget> createState() => _ACControlWidgetState();
}

class _ACControlWidgetState extends State<ACControlWidget> {
  int _selectedMode = 0; // 0: Cooling, 1: Heating...
  double _temp = 20.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs chọn chế độ
        _buildModeTabs(),
        const SizedBox(height: 40),
        // Vòng tròn nhiệt độ (Sử dụng Stack và CustomPaint hoặc Image minh họa)
        _buildTempCircle(),
        const Spacer(),
        // Grid các phím chức năng dưới (Eco, Sleep, Timer...)
        _buildFeatureGrid(),
      ],
    );
  }

  Widget _buildModeTabs() {
    List<String> modes = ["Cooling", "Heating", "Purifying"];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: List.generate(modes.length, (index) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedMode == index ? const Color(0xFF4B6EF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(modes[index], textAlign: TextAlign.center, 
                style: TextStyle(color: _selectedMode == index ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildTempCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Vòng cung (Chồng dùng placeholder, vợ có thể dùng package 'sleek_circular_slider' để kéo xoay nhé)
        SizedBox(width: 250, height: 250, child: CircularProgressIndicator(value: 0.7, strokeWidth: 15, color: const Color(0xFF4B6EF6), backgroundColor: Colors.grey[200])),
        Column(
          children: [
            Text("${_temp.toInt()}°C", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const Text("Temperature", style: TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true, crossAxisCount: 4, padding: const EdgeInsets.all(24),
      children: [
        _featureItem(Icons.tune, "Mode"),
        _featureItem(Icons.air, "Wind Speed"),
        _featureItem(Icons.swap_calls, "Wind Direct."),
        _featureItem(Icons.filter_center_focus, "Precision"),
        _featureItem(Icons.eco, "Eco"),
        _featureItem(Icons.nightlight_round, "Sleep"),
        _featureItem(Icons.timer, "Timer"),
        _featureItem(Icons.grid_view, "More"),
      ],
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center),
      ],
    );
  }
}