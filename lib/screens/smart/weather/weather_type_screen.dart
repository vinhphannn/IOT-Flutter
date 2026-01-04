import 'package:flutter/material.dart';
import 'weather_base_screen.dart';

class WeatherTypeScreen extends StatefulWidget {
  const WeatherTypeScreen({super.key});

  @override
  State<WeatherTypeScreen> createState() => _WeatherTypeScreenState();
}

class _WeatherTypeScreenState extends State<WeatherTypeScreen> {
  String _selected = "Rainy";
  final List<String> _options = ["Sunny", "Cloudy", "Rainy", "Snowy", "Hazy"];

  @override
  Widget build(BuildContext context) {
    return WeatherBaseScreen(
      title: "Weather",
      // 👇 SỬA NÚT CONTINUE
      onContinue: () {
        Navigator.pop(context, {
          "type": "WEATHER_CONDITION",
          "operator": "==", 
          "value": _selected.toUpperCase(), // Gửi SUNNY, RAINY... lên BE
          
          // Dữ liệu UI
          "displayTitle": "Weather is $_selected",
          "displaySubtitle": "New York City",
          "icon": Icons.wb_sunny, // Icon đại diện
          "color": Colors.orange,
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