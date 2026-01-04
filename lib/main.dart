import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/navigation_service.dart';
import 'routes.dart';
import 'config/app_config.dart'; // Đảm bảo file AppConfig mới nằm ở đây
// ... import provider ...
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'providers/house_provider.dart';
import 'providers/smart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- CẬP NHẬT MỚI ---
  // Thay vì chỉ load chuỗi, giờ mình gọi hàm check kết nối thông minh
  // Nó sẽ tự động ping server, nếu chết thì đổi sang Koyeb/Emulator
  await AppConfig.loadConfig();
  
  // Khóa màn hình dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Bọc toàn bộ MyApp trong MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // Khởi tạo DeviceProvider ngay từ lúc App mới mở mắt
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => HouseProvider()),
        ChangeNotifierProvider(create: (_) => SmartProvider()),
        
        // Sau này thêm các Provider khác vào đây
      ],
      child: const MyApp(), // MyApp bây giờ là con của Provider
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smartify',
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color.fromARGB(255, 1, 96, 197),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
        ),
      ),
      // --- LUÔN BẮT ĐẦU TỪ SPLASH ---
      // Tại màn hình Splash, vợ có thể kiểm tra lại biến AppConfig.baseUrl
      // xem nó đang nhận IP nào nhé.
      initialRoute: AppRoutes.splash, 
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}