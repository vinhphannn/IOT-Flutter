import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes.dart';// Import file routes vừa tạo

void main() {
  // Đảm bảo Flutter binding đã khởi tạo trước khi làm việc khác
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khoá màn hình dọc (App IoT thường dùng chiều dọc)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smartify',
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG ở góc phải

      // Cấu hình Theme chung cho toàn App (giống thiết kế của bạn)
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color.fromARGB(255, 1, 96, 197), // Màu xanh dương chủ đạo (dự kiến)
        scaffoldBackgroundColor: Colors.white, // Nền trắng
        
        // Cấu hình AppBar mặc định
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),

        // Cấu hình nút bấm (ElevatedButton) mặc định là màu xanh, bo tròn
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2), // Màu nút
            foregroundColor: Colors.white, // Màu chữ
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Bo tròn như thiết kế
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
        ),
      ),

      // --- CẤU HÌNH ROUTE ---
      initialRoute: AppRoutes.splash, // Màn hình đầu tiên chạy lên
      onGenerateRoute: AppRoutes.generateRoute, // Hàm xử lý điều hướng
    );
  }
}