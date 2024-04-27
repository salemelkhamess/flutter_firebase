class Product {
  final String id;
  final String name;
  final double price;
  final int qty;
  String? imageUrl; // Add a property for the image URL (nullable)
  List<String>? imageUrls; // Liste d'URLs de la galerie d'images (nullable)

  Product(
      {required this.qty,
      required this.id,
      required this.name,
      required this.price,
      this.imageUrl,
      this.imageUrls});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'imageUrl': imageUrl, // Add imageUrl to the map
      'imageUrls': imageUrls, // Add imageUrl to the map
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      qty: map['qty'],
      imageUrl: map['imageUrl'], // Access the imageUrl from the map
      imageUrls: map['imageUrls'], // Access the imageUrl from the map
    );
  }
}
