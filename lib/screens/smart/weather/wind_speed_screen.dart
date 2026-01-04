import 'package:flutter/material.dart';
import 'weather_base_screen.dart';

class WindSpeedScreen extends StatefulWidget {
  const WindSpeedScreen({super.key});

  @override
  State<WindSpeedScreen> createState() => _WindSpeedScreenState();
}

class _WindSpeedScreenState extends State<WindSpeedScreen> {
  int _selectedOperator = 2; // 0: <, 1: =, 2: >
  double _windValue = 45.0;

  @override
  Widget build(BuildContext context) {
    return WeatherBaseScreen(
      title: "Wind Speed",
      // 👇 SỬA NÚT CONTINUE
      onContinue: () {
        // 1. Map toán tử
        String opSymbolForBE = _selectedOperator == 0 ? "<" : (_selectedOperator == 1 ? "==" : ">");
        String opSymbolForUI = _selectedOperator == 0 ? "<" : (_selectedOperator == 1 ? "=" : ">");

        // 2. Trả dữ liệu về
        Navigator.pop(context, {
          "type": "WEATHER_WIND",       // Loại điều kiện BE
          "operator": opSymbolForBE,    
          "value": _windValue.round().toString(), 
          
          // Dữ liệu UI
          "displayTitle": "Wind Speed: $opSymbolForUI ${_windValue.round()} m/s",
          "displaySubtitle": "New York City",
          "icon": Icons.air,
          "color": Colors.blueGrey,
        });
      },
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                _buildOpButton("<", 0),
                _buildOpButton("=", 1),
                _buildOpButton(">", 2),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          RichText(
            text: TextSpan(
              text: "${_windValue.round()}",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500, color: Colors.black),
              children: const [TextSpan(text: " m/s", style: TextStyle(fontSize: 24, color: Colors.grey))],
            ),
          ),
          
          const SizedBox(height: 40),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              activeTrackColor: const Color(0xFF4B6EF6),
              inactiveTrackColor: Colors.grey[200],
            ),
            child: Slider(
              value: _windValue,
              min: 0,
              max: 62,
              onChanged: (val) => setState(() => _windValue = val),
            ),
          ),
          
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("0 m/s", style: TextStyle(color: Colors.grey)), Text("62 m/s", style: TextStyle(color: Colors.grey))],
          )
        ],
      ),
    );
  }

  Widget _buildOpButton(String label, int index) {
    bool isSelected = _selectedOperator == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOperator = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4B6EF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
        ),
      ),
    );
  }
}