class House {
  final int id;
  final String name;
  final String address;

  House({
    required this.id,
    required this.name,
    required this.address,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'] ?? "Unnamed House",
      address: json['address'] ?? "",
    );
  }
}