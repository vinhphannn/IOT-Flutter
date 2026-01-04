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
    // --- THAY ĐỔI QUAN TRỌNG Ở ĐÂY ---
    // Gọi hàm loadConfig thông minh để nó tự chọn URL (Koyeb hoặc Local cũ)
    await AppConfig.loadConfig(); 
    
    // Sau khi AppConfig chọn xong URL, kiểm tra lại xem có mạng không
    bool isConnected = await ApiClient.checkConnection();

    if (!isConnected) {
      if (mounted) {
        // Nếu mất mạng hoặc URL chết -> Hiện bảng nhập IP
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ServerConfigDialog(
            // Khi lưu IP mới xong thì chạy lại quy trình từ đầu
            onSaved: () {
              Navigator.pop(context); // Tắt dialog
              _startAppFlow(); // Thử lại
            } 
          ),
        );
      }
    } else {
      // Mạng ngon -> Kiểm tra đăng nhập
      _checkLoginStatus();
    }
  }

  void _checkLoginStatus() async {
    // Đợi xíu cho hiệu ứng đẹp (tùy chọn)
    await Future.delayed(const Duration(milliseconds: 800)); 

    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final String? token = prefs.getString('jwt_token');
    
    // 1. Chưa có Token -> Chưa đăng nhập
    if (token == null || token.isEmpty) {
      _navigateToAuth(seenOnboarding);
      return;
    }

    // 2. Có Token -> Gọi thử API lấy danh sách nhà để xem Token còn sống không
    try {
      HouseService houseService = HouseService();
      final houses = await houseService.fetchMyHouses();

      if (!mounted) return;

      if (houses.isNotEmpty) {
        // Token sống + Có nhà -> Vào thẳng màn hình chính
        await prefs.setBool('is_setup_completed', true);
        
        // Lưu lại nhà đầu tiên làm mặc định nếu chưa có
        if (prefs.getInt('currentHouseId') == null) {
          await prefs.setInt('currentHouseId', houses[0].id);
        }
        
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // Token sống nhưng chưa tạo nhà -> Sang màn hình tạo nhà (Setup)
        await prefs.setBool('is_setup_completed', false);
        Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
      }
    } catch (e) {
      print("🚨 Splash Error (Thường do Token hết hạn hoặc Lỗi Server): $e");
      
      if (!mounted) return;

      // NẾU LỖI (401/403): Đá về màn hình Login
      await prefs.remove('jwt_token'); 
      _navigateToAuth(seenOnboarding);
    }
  }

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
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: size.width * 0.25,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.smart_toy, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Tên App
            const Text(
              'Smartify', 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            const SizedBox(height: 40),
            // Vòng quay loading
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
            ),
          ],
        ),
      ),
    );
  }
}