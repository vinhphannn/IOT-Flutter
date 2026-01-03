class Room {
  final int id;
  final String name;
  final String? imageUrl;

  Room({required this.id, required this.name, this.imageUrl});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }
}