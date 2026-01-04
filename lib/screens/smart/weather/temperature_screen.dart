import 'package:flutter/material.dart';
import 'weather_base_screen.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  int _selectedOperator = 2; // 0: <, 1: =, 2: > (Mặc định chọn >)
  double _tempValue = 20.0; // Giá trị mặc định

  @override
  Widget build(BuildContext context) {
    return WeatherBaseScreen(
      title: "Temperature",
      // 👇 SỬA LOGIC NÚT CONTINUE Ở ĐÂY
      onContinue: () {
        // 1. Xác định toán tử để gửi Backend (Backend thường cần "==" thay vì "=")
        String opSymbolForBE = _selectedOperator == 0 ? "<" : (_selectedOperator == 1 ? "==" : ">");
        
        // 2. Xác định toán tử để hiển thị lên UI (cho đẹp mắt)
        String opSymbolForUI = _selectedOperator == 0 ? "<" : (_selectedOperator == 1 ? "=" : ">");

        // 3. Trả dữ liệu về trang trước
        Navigator.pop(context, {
          "type": "WEATHER_TEMP",       // Loại điều kiện BE cần (khớp với JSON mẫu)
          "operator": opSymbolForBE,    // Toán tử (<, ==, >)
          "value": _tempValue.round().toString(), // Giá trị (VD: "20")
          
          // Dữ liệu để hiển thị thẻ màu đỏ bên ngoài
          "displayTitle": "Temperature: $opSymbolForUI ${_tempValue.round()}°C",
          "displaySubtitle": "New York City",
          "icon": Icons.thermostat,
          "color": Colors.redAccent,
        });
      },
      child: Column(
        children: [
          // 3 Nút chọn Operator < = >
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
          
          // Hiển thị số to
          Text("${_tempValue.round()}°C", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500)),
          
          const SizedBox(height: 40),

          // Thanh trượt Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              activeTrackColor: const Color(0xFF4B6EF6),
              inactiveTrackColor: Colors.grey[200],
            ),
            child: Slider(
              value: _tempValue,
              min: -50,
              max: 50,
              onChanged: (val) => setState(() => _tempValue = val),
            ),
          ),
          
          // Label min/max
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("-50°C", style: TextStyle(color: Colors.grey)), Text("50°C", style: TextStyle(color: Colors.grey))],
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