class AppConfig {
  // --- CHỌN 1 TRONG 2 DÒNG DƯỚI ĐÂY ĐỂ DÙNG ---

  // 1. Nếu vợ chạy trên Máy ảo Android (Emulator):
  static const String baseUrl = "http://10.0.2.2:8080/api"; 

  // 2. Nếu vợ chạy trên Điện thoại thật (Cùng Wifi):
  // Thay số 123 bằng IP thật của máy tính vợ (Mở cmd gõ ipconfig để xem IPv4)
  // static const String baseUrl = "http://192.168.1.123:8080/api"; 
}