import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HomeWeatherWidget extends StatefulWidget {
  const HomeWeatherWidget({super.key});

  @override
  State<HomeWeatherWidget> createState() => _HomeWeatherWidgetState();
}

class _HomeWeatherWidgetState extends State<HomeWeatherWidget> {
  bool _isLoadingWeather = true;
  String _temp = "--";
  String _cityName = "Locating...";
  String _weatherDesc = "Checking...";
  String _humidity = "-";
  String _windSpeed = "-";
  String _weatherIconCode = "02d";

  final String _apiKey = "9d7d651e4671cadec782b9a990c7d992";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() { _cityName = "GPS Off"; _isLoadingWeather = false; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showLocationDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() { _cityName = "Blocked"; _isLoadingWeather = false; });
      return;
    }

    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoadingWeather = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey');
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _temp = data['main']['temp'].round().toString();
            _cityName = data['name'];
            _weatherDesc = data['weather'][0]['main'];
            _humidity = data['main']['humidity'].toString();
            _windSpeed = data['wind']['speed'].toString();
            _weatherIconCode = data['weather'][0]['icon'];
            _isLoadingWeather = false;
          });
        }
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    if (mounted) {
      setState(() {
        _temp = "28"; _cityName = "Ho Chi Minh"; _weatherDesc = "Clouds";
        _humidity = "75"; _windSpeed = "3.5"; _weatherIconCode = "02d";
        _isLoadingWeather = false; 
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF4B6EF6), size: 50),
              const SizedBox(height: 16),
              const Text("Enable Location", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Please enable location to see local weather.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () { Navigator.pop(context); _useFallbackData(); },
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openAppSettings();
                      _checkLocationPermission();
                    },
                    child: const Text("Settings", style: TextStyle(color: Color(0xFF4B6EF6), fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 180, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B6EF6), Color(0xFF7B96FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF4B6EF6).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: _isLoadingWeather 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_temp°C", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_cityName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("Today $_weatherDesc", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildWeatherInfo(Icons.air, "AQI 90"),
                      const SizedBox(width: 15),
                      _buildWeatherInfo(Icons.water_drop_outlined, "$_humidity%"),
                      const SizedBox(width: 15),
                      _buildWeatherInfo(Icons.wind_power, "$_windSpeed m/s"),
                    ],
                  )
                ],
              ),
              Positioned(
                right: -10, top: -10,
                child: SizedBox(
                  width: 140, height: 140,
                  child: Image.network(
                    "https://openweathermap.org/img/wn/$_weatherIconCode@4x.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.cloud, size: 100, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
              )
            ],
          ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}