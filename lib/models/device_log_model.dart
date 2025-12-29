class DeviceLog {
  final int id;
  final String action;
  final String details; // Thêm trường này cho chi tiết hơn
  final DateTime timestamp;
  final String roomName;

  DeviceLog({
    required this.id,
    required this.action,
    required this.details,
    required this.timestamp,
    this.roomName = "Smart Home",
  });

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: json['id'] ?? 0,
      action: json['action'] ?? "UNKNOWN",
      details: json['details'] ?? "",
      // SỬA Ở ĐÂY: Dùng key 'timestamp' thay vì 'createdAt'
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      // Lấy room name từ nested object
      roomName: json['device'] != null && 
                json['device']['room'] != null 
          ? json['device']['room']['name'] 
          : "Smart Home",
    );
  }
}