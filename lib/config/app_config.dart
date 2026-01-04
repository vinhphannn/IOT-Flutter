import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Nhớ import cái này để check kết nối

class AppConfig {
  // 1. CÁC URL MẶC ĐỊNH
  // Link Server Koyeb (Chạy online ổn định nhất)
  static const String _koyebUrl = "https://operational-kellia-vinhphan-0c3fa64b.koyeb.app/api";
  
  // Link Máy ảo Android (Dự phòng khi chạy local)
  static const String _emulatorUrl = "http://10.0.2.2:8080/api";

  // Biến lưu URL hiện tại đang dùng (Mặc định dùng Koyeb cho xịn)
  static String baseUrl = _koyebUrl; 

  static const String _keyBaseUrl = 'saved_base_url';

  // --- LOGIC WEBSOCKET TỰ ĐỘNG ---
  static String get webSocketUrl {
    // Tự động đổi http -> ws, https -> wss
    String host = baseUrl.replaceAll("/api", ""); 
    if (host.startsWith("https")) {
      return host.replaceFirst("https", "wss") + "/ws";
    } else {
      return host.replaceFirst("http", "ws") + "/ws";
    }
  }

  // --- HÀM 1: LOAD VÀ CHECK KẾT NỐI KHI MỞ MÁY ---
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString(_keyBaseUrl);

    // Ưu tiên 1: Kiểm tra URL đã lưu trước đó (IP máy thật vợ từng nhập)
    if (savedUrl != null && savedUrl.isNotEmpty) {
      print("🔍 Đang kiểm tra kết nối tới URL đã lưu: $savedUrl ...");
      bool isAlive = await _checkConnection(savedUrl);
      
      if (isAlive) {
        baseUrl = savedUrl;
        print("✅ URL đã lưu hoạt động tốt!");
        return; // Xong việc, thoát luôn
      } else {
        print("❌ URL đã lưu không kết nối được. Chuyển sang phương án dự phòng...");
      }
    }

    // Ưu tiên 2: Nếu URL lưu bị lỗi -> Dùng Server Koyeb (hoặc Máy ảo)
    // Vợ muốn ưu tiên cái nào thì gán vào đây
    baseUrl = _koyebUrl; // Hoặc đổi thành _emulatorUrl nếu vợ đang test offline
    print("⚠️ Đang sử dụng URL mặc định: $baseUrl");
  }

  // --- HÀM 2: LƯU URL MỚI (Dùng cho màn hình nhập IP) ---
  // Trả về true nếu kết nối thành công, false nếu thất bại
  static Future<bool> setBaseUrl(String newUrl) async {
    // Chuẩn hóa chuỗi (bỏ dấu / ở cuối nếu có)
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }
    
    // Nếu người dùng quên nhập /api, tự thêm vào cho họ (cho tiện)
    if (!newUrl.endsWith("/api")) {
      newUrl = "$newUrl/api";
    }

    print("🔄 Đang thử kết nối URL mới: $newUrl ...");
    // Kiểm tra sống chết trước khi lưu
    bool isAlive = await _checkConnection(newUrl);

    if (isAlive) {
      baseUrl = newUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, baseUrl);
      print("✅ Đã lưu cấu hình mới thành công!");
      return true;
    } else {
      print("❌ URL này không truy cập được!");
      return false;
    }
  }

  // --- HÀM PHỤ: PING SERVER ---
  static Future<bool> _checkConnection(String url) async {
    try {
      // Gọi thử vào 1 API nhẹ nhất (ví dụ /auth/login hoặc chỉ gọi root)
      // Ở đây chồng gọi thử chính cái url đó xem server có phản hồi không
      // Timeout 3 giây thôi, không đợi lâu
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      
      // Chỉ cần không lỗi mạng là tính OK (kể cả 401, 404 nghĩa là server vẫn sống)
      return true; 
    } catch (e) {
      return false;
    }
  }
}