import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../services/house_service.dart';
import '../../widgets/server_config_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  void _startAppFlow() async {
    await AppConfig.loadBaseUrl();
    bool isConnected = await ApiClient.checkConnection();

    if (!isConnected) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ServerConfigDialog(onSaved: () => _startAppFlow()),
        );
      }
    } else {
      _checkLoginStatus();
    }
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 800)); 

    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final String? token = prefs.getString('jwt_token');
    
    if (token == null || token.isEmpty) {
      _navigateToAuth(seenOnboarding);
      return;
    }

    // Nếu có Token, phải thử gọi API để xem Token còn sống không
    try {
      HouseService houseService = HouseService();
      // Gọi API này để "thử lửa" Token
      final houses = await houseService.fetchMyHouses();

      if (!mounted) return;

      if (houses.isNotEmpty) {
        await prefs.setBool('is_setup_completed', true);
        if (prefs.getInt('currentHouseId') == null) {
          await prefs.setInt('currentHouseId', houses[0].id);
        }
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // Token sống nhưng chưa có nhà -> Bắt buộc setup
        await prefs.setBool('is_setup_completed', false);
        Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
      }
    } catch (e) {
      print("🚨 Splash Error (Thường do Token hết hạn): $e");
      
      if (!mounted) return;

      // NẾU LỖI API: Tuyệt đối không cho vào Home. 
      // Xóa token cũ đi và đá về màn hình Login để lấy token mới.
      await prefs.remove('jwt_token'); 
      _navigateToAuth(seenOnboarding);
    }
  }

  // Hàm phụ để điều hướng gọn hơn
  void _navigateToAuth(bool seenOnboarding) {
    if (seenOnboarding) {
      Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: size.width * 0.25,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.smart_toy, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('Smartify', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}