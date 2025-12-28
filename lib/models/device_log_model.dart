class DeviceLog {
  final int id;
  final String action;
  final DateTime timestamp;
  final String roomName;

  DeviceLog({required this.id, required this.action, required this.timestamp, required this.roomName});

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: json['id'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      roomName: json['device']['room']['name'],
    );
  }
}