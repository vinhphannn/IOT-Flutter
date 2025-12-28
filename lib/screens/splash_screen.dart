import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../services/house_service.dart'; // <--- Import thêm cái này
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

  // --- LOGIC ĐÃ ĐƯỢC NÂNG CẤP ---
  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Giảm thời gian chờ xuống xíu cho nhanh

    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final String? token = prefs.getString('jwt_token');
    
    // Check sơ bộ: Có token không?
    final bool hasToken = token != null && token.isNotEmpty;

    if (!mounted) return;

    if (hasToken) {
      // --- BƯỚC KIỂM TRA QUAN TRỌNG VỚI SERVER ---
      try {
        // Hỏi Server: "User này có nhà nào chưa?"
        HouseService houseService = HouseService();
        final houses = await houseService.fetchMyHouses();

        if (houses.isNotEmpty) {
          // A. Có nhà rồi -> Đánh dấu đã setup -> Vào Home
          await prefs.setBool('is_setup_completed', true);
          
          // Lưu ID nhà đầu tiên làm mặc định nếu chưa có
          if (prefs.getInt('currentHouseId') == null) {
             await prefs.setInt('currentHouseId', houses[0].id);
          }

          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          // B. Chưa có nhà nào (List rỗng) -> Vào trang Setup
          // (Dù trước đó local có lưu true thì giờ server bảo chưa có cũng phải tin server)
          await prefs.setBool('is_setup_completed', false);
          Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
        }
      } catch (e) {
        // C. Lỗi mạng hoặc Token hết hạn lúc gọi API House
        print("Lỗi check Setup status: $e");
        
        // Nếu lỗi 401 Unauthorized -> Đá về Login
        if (e.toString().contains("401") || e.toString().contains("UNAUTHORIZED")) {
           Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
        } else {
           // Nếu lỗi mạng khác thì tạm tin vào Local Storage (Fallback)
           // Để người dùng vẫn vào được App (chế độ offline)
           final bool localSetupCompleted = prefs.getBool('is_setup_completed') ?? false;
           if (localSetupCompleted) {
             Navigator.pushReplacementNamed(context, AppRoutes.home);
           } else {
             Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
           }
        }
      }
    } else {
      // Chưa đăng nhập
      if (seenOnboarding) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.25,
                    height: size.width * 0.25,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.smart_toy, size: 60, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Smartify', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text("Server: ${AppConfig.baseUrl}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            const Expanded(
              flex: 1,
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 3)),
            ),
          ],
        ),
      ),
    );
  }
}