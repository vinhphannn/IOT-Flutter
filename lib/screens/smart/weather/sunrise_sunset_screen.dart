import 'package:flutter/material.dart';
import 'weather_base_screen.dart';

class SunriseSunsetScreen extends StatefulWidget {
  const SunriseSunsetScreen({super.key});

  @override
  State<SunriseSunsetScreen> createState() => _SunriseSunsetScreenState();
}

class _SunriseSunsetScreenState extends State<SunriseSunsetScreen> {
  String _selected = "Sunset";
  final List<String> _options = ["Sunset", "Sunrise"];

  @override
  Widget build(BuildContext context) {
    return WeatherBaseScreen(
      title: "Sunrise / Sunset",
      // 👇 SỬA NÚT CONTINUE ĐỂ TRẢ DỮ LIỆU VỀ
      onContinue: () {
        Navigator.pop(context, {
          "type": "WEATHER_SUN",        // Loại điều kiện cho BE
          "operator": "==",             // So sánh bằng
          "value": _selected.toUpperCase(), // Giá trị gửi BE (VD: "SUNSET")
          
          // Dữ liệu hiển thị UI
          "displayTitle": "Sun State: $_selected",
          "displaySubtitle": "New York City",
          "icon": Icons.wb_twilight,
          "color": Colors.amber,
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