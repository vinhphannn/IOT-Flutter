import 'package:flutter/material.dart';

// --- IMPORT MODELS ---
import 'models/device_model.dart'; // Model Device thật
import 'screens/device/tabs/nearby_scan_tab.dart'; // Model DeviceItem (quét)

// --- IMPORT CÁC MÀN HÌNH ---
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
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
import 'screens/main_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/voice/voice_assistant_screen.dart';

// --- IMPORT MÀN HÌNH THIẾT BỊ ---
import 'screens/device/add_device_screen.dart';
import 'screens/device/connect_device_screen.dart';
import 'screens/device/connected_success_screen.dart';
import 'screens/device/qr_scan_screen.dart';
import 'screens/control/device_control_screen.dart';

class AppRoutes {
  // --- ĐỊNH NGHĨA TÊN ROUTES ---
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
  static const String scanQR = '/scan-qr';
  static const String notification = '/notification';
  static const String chat = '/chat';
  static const String voiceAssistant = '/voice-assistant';
  static const String controlDevice = '/control-device';

  // --- HÀM ĐIỀU HƯỚNG ---
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Lấy tham số truyền vào (nếu có)
    final args = settings.arguments;

    switch (settings.name) {
      // 1. Màn hình khởi động & Chào mừng
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case loginOptions:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      // 2. Màn hình Auth (Đăng nhập, Đăng ký, Quên mật khẩu)
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case signUpSetup:
        return MaterialPageRoute(builder: (_) => const SetupScreen());
      case signUpComplete:
        return MaterialPageRoute(builder: (_) => const SignUpCompleteScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      // --- CÁC CHỖ SỬA QUAN TRỌNG ĐỂ TRUYỀN DATA ---
      case otpVerification:
        return MaterialPageRoute(
          builder: (_) => const OtpVerificationScreen(),
          settings: settings, // <--- QUAN TRỌNG: Phải có dòng này mới nhận được Email
        );
      
      case resetPassword:
        return MaterialPageRoute(
          builder: (_) => const NewPasswordScreen(),
          settings: settings, // <--- QUAN TRỌNG: Phải có dòng này mới nhận được OTP & Email
        );

      case resetPasswordSuccess:
        return MaterialPageRoute(builder: (_) => const ResetPasswordSuccessScreen());
      
      // 3. Màn hình chính
      case home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case notification:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case voiceAssistant:
        return MaterialPageRoute(builder: (_) => const VoiceAssistantScreen());

      // 4. Màn hình thiết bị (Add, Connect, Control)
      case addDevice:
        return MaterialPageRoute(builder: (_) => const AddDeviceScreen());
      
      case scanQR:
        return MaterialPageRoute(builder: (_) => const QRScanScreen());

      case connectDevice:
        // Nhận DeviceItem (lúc quét)
        final deviceItem = settings.arguments as DeviceItem;
        return MaterialPageRoute(
          builder: (_) => ConnectDeviceScreen(device: deviceItem),
          // Ở đây không cần settings: settings vì mình đã truyền qua constructor rồi
        );

      case connectedSuccess:
        // Nhận Device (Model thật)
        final device = settings.arguments as Device;
        return MaterialPageRoute(
          builder: (_) => ConnectedSuccessScreen(device: device),
        );

      case controlDevice:
        // Nhận Device để điều khiển
        final deviceToControl = settings.arguments as Device;
        return MaterialPageRoute(
          builder: (_) => DeviceControlScreen(device: deviceToControl),
        );

      // 5. Màn hình tạm (Placeholder)
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