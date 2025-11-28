class BusinessType {
  final String id;
  final String name;
  final String icon;

  BusinessType({required this.id, required this.name, required this.icon});

  factory BusinessType.fromJson(Map<String, dynamic> json) {
    return BusinessType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon};
  }

  // Predefined business types
  static List<BusinessType> getDefaultTypes() {
    return [
      BusinessType(id: 'grocery', name: 'Grocery', icon: '🛒'),
      BusinessType(id: 'cafe', name: 'Cafe', icon: '☕'),
      BusinessType(id: 'hotel', name: 'Hotel', icon: '🏨'),
      BusinessType(id: 'dairy', name: 'Dairy', icon: '🥛'),
      BusinessType(id: 'restaurant', name: 'Restaurant', icon: '🍽️'),
      BusinessType(id: 'bakery', name: 'Bakery', icon: '🍞'),
      BusinessType(id: 'pharmacy', name: 'Pharmacy', icon: '💊'),
      BusinessType(id: 'supermarket', name: 'Supermarket', icon: '🏪'),
      BusinessType(id: 'others', name: 'Others', icon: '📦'),
    ];
  }
}
