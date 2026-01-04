import 'package:flutter/material.dart';
// Import các trang con
import 'weather/temperature_screen.dart';
import 'weather/humidity_screen.dart';
import 'weather/weather_type_screen.dart';
import 'weather/sunrise_sunset_screen.dart';
import 'weather/wind_speed_screen.dart';

class WeatherConditionScreen extends StatelessWidget {
  const WeatherConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Màu nền xám nhạt
      appBar: AppBar(
        title: const Text(
          "When Weather Changes",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Đổ bóng nhẹ
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Co gọn theo nội dung
            children: [
              // 1. TEMPERATURE
              _buildWeatherItem(
                icon: Icons.thermostat,
                color: Colors.redAccent,
                title: "Temperature",
                onTap: () async {
                  // Chờ kết quả từ trang con
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TemperatureScreen()),
                  );
                  // Nếu có kết quả, trả về trang CreateSceneScreen ngay lập tức
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const Divider(height: 1, indent: 60, endIndent: 20),

              // 2. HUMIDITY
              _buildWeatherItem(
                icon: Icons.water_drop,
                color: Colors.blue,
                title: "Humidity",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HumidityScreen()),
                  );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const Divider(height: 1, indent: 60, endIndent: 20),

              // 3. WEATHER TYPE
              _buildWeatherItem(
                icon: Icons.wb_sunny,
                color: Colors.orange,
                title: "Weather",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeatherTypeScreen()),
                  );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const Divider(height: 1, indent: 60, endIndent: 20),

              // 4. SUNRISE / SUNSET
              _buildWeatherItem(
                icon: Icons.wb_twilight,
                color: Colors.amber,
                title: "Sunrise / Sunset",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SunriseSunsetScreen(),
                    ),
                  );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const Divider(height: 1, indent: 60, endIndent: 20),

              // 5. WIND SPEED
              _buildWeatherItem(
                icon: Icons.air,
                color: Colors.blueGrey,
                title: "Wind Speed",
                isLast: true,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WindSpeedScreen()),
                  );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con để vẽ từng dòng
  Widget _buildWeatherItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            // Icon bên trái
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 20),

            // Tên mục
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Chữ đậm vừa phải
                  color: Colors.black87,
                ),
              ),
            ),

            // Mũi tên bên phải
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}