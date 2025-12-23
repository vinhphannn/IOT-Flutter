import 'package:flutter/material.dart';

// 1. Import các màn hình đã làm xong
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart'; // <-- MỚI THÊM DÒNG NÀY
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/auth/sign_up_complete_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/auth/reset_password_success_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/device/add_device_screen.dart';
import 'screens/device/connect_device_screen.dart';
import 'screens/device/connected_success_screen.dart';

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
  static const String signUpComplete = '/sign-up-complete';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String resetPasswordSuccess = '/reset-password-success';
  static const String addDevice = '/add-device';
  static const String connectDevice = '/connect-device';
  static const String connectedSuccess = '/connected-success';

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
        return MaterialPageRoute(builder: (_) => const SignInScreen());

      // 2. Thêm case mới
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      // 2. Thêm case mới
      case otpVerification:
        return MaterialPageRoute(builder: (_) => const OtpVerificationScreen());

      case resetPassword:
        return MaterialPageRoute(builder: (_) => const NewPasswordScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case signUpSetup:
        return MaterialPageRoute(builder: (_) => const SetupScreen());
      case signUpComplete:
        return MaterialPageRoute(builder: (_) => const SignUpCompleteScreen());
      case otp:
        return MaterialPageRoute(
          builder: (_) => PlaceholderScreen(title: 'Nhập OTP cho: $args'),
        );

      case resetPasswordSuccess:
        return MaterialPageRoute(
          builder: (_) => const ResetPasswordSuccessScreen(),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case addDevice: // <-- Thêm case này
        return MaterialPageRoute(builder: (_) => const AddDeviceScreen());

      case connectDevice:
        // Lấy dữ liệu DeviceItem được truyền sang
        final device = settings.arguments as DeviceItem;
        return MaterialPageRoute(
          builder: (_) => ConnectDeviceScreen(device: device),
        );

      case connectedSuccess:
        final device = settings.arguments as DeviceItem;
        return MaterialPageRoute(
          builder: (_) => ConnectedSuccessScreen(device: device),
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
