class Room {
  final int id;
  final String name;
  // final int houseId; // Nếu cần dùng sau này

  Room({
    required this.id,
    required this.name,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'] ?? "Phòng không tên",
    );
  }
  
  // Hàm hỗ trợ hiển thị trong Dropdown
  @override
  String toString() => name;
}