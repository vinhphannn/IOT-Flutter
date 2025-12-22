import 'package:flutter/material.dart';

// 1. Import các màn hình đã làm xong
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart'; // <-- MỚI THÊM DÒNG NÀY
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/setup/setup_screen.dart';

class AppRoutes {
  // Định nghĩa tên Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String terms = '/terms';
  static const String loginOptions = '/login-options';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String signUpSetup = '/setup';

  // Hàm điều hướng
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Lấy tham số truyền vào (nếu có)
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case onboarding:
        // Đã import ở trên nên dòng này giờ sẽ chạy ngon lành
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      // --- Các màn hình chưa làm thì dùng Placeholder tạm ---
      case loginOptions:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case signIn:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(title: 'Sign In (Đăng nhập)'),
        );

      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case signUpSetup: 
        return MaterialPageRoute(builder: (_) => const SetupScreen());
      case otp:
        return MaterialPageRoute(
          builder: (_) => PlaceholderScreen(title: 'Nhập OTP cho: $args'),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(title: 'Home Dashboard'),
        );

      default:
        return _errorRoute();
    }
  }

  // Trang báo lỗi 404
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Lỗi')),
          body: const Center(child: Text('Không tìm thấy màn hình này!')),
        );
      },
    );
  }
}

// --- WIDGET TẠM (Giữ lại để test chuyển trang, sau này xóa sau) ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đây là màn hình: $title',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic test chuyển trang
                if (title == 'Splash Screen')
                  Navigator.pushNamed(context, AppRoutes.onboarding);
                // Nếu đang ở Onboarding hoặc Login thì về Home
                else
                  Navigator.pushNamed(context, AppRoutes.home);
              },
              child: const Text('Test chuyển trang kế tiếp'),
            ),
          ],
        ),
      ),
    );
  }
}
