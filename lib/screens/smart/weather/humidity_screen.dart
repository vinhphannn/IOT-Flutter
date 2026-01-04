import 'package:flutter/material.dart';
import 'weather_base_screen.dart';

class HumidityScreen extends StatefulWidget {
  const HumidityScreen({super.key});

  @override
  State<HumidityScreen> createState() => _HumidityScreenState();
}

class _HumidityScreenState extends State<HumidityScreen> {
  String _selected = "Dry";
  final List<String> _options = ["Dry", "Comfortable", "Moist"];

  @override
  Widget build(BuildContext context) {
    return WeatherBaseScreen(
      title: "Humidity",
      // 👇 SỬA NÚT CONTINUE ĐỂ TRẢ DỮ LIỆU VỀ
      onContinue: () {
        Navigator.pop(context, {
          "type": "WEATHER_HUMIDITY",   // Loại điều kiện cho BE
          "operator": "==",             // So sánh bằng
          "value": _selected.toUpperCase(), // Giá trị gửi BE (VD: "DRY")
          
          // Dữ liệu hiển thị UI
          "displayTitle": "Humidity: $_selected",
          "displaySubtitle": "New York City",
          "icon": Icons.water_drop,
          "color": Colors.blue,
        });
      },
      child: Column(
        children: _options.map((opt) => RadioListTile<String>(
          title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: opt,
          groupValue: _selected,
          activeColor: const Color(0xFF4B6EF6),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _selected = val!),
        )).toList(),
      ),
    );
  }
}