class MenuItem {
  final String id;
  final String name;
  final double price;
  final String uom;
  final String image;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.uom,
    required this.image,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, double price) {
    return MenuItem(
      id: map['ctr']?.toString() ?? '',
      name: map['itemname']?.toString() ?? 'Unknown Item',
      price: price,
      uom: map['uom']?.toString() ?? '',
      image: '',
    );
  }
}