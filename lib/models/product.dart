class Product {
  final String? id;
  final String name;
  final String? category;
  final int price;
  final int hpp;
  final bool ready;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    this.id,
    required this.name,
    this.category,
    required this.price,
    this.hpp = 0,
    this.ready = true,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        'hpp': hpp,
        'ready': ready,
        'archived': archived,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Product.fromJson(Map<String, dynamic> json, String id) => Product(
        id: id,
        name: json['name'] as String,
        category: json['category'] as String?,
        price: json['price'] as int,
        hpp: json['hpp'] as int? ?? 0,
        ready: json['ready'] as bool? ?? true,
        archived: json['archived'] as bool? ?? false,
        createdAt: (json['createdAt'] as dynamic).toDate(),
        updatedAt: (json['updatedAt'] as dynamic).toDate(),
      );

  Product copyWith({
    String? name,
    String? category,
    int? price,
    int? hpp,
    bool? ready,
    bool? archived,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        price: price ?? this.price,
        hpp: hpp ?? this.hpp,
        ready: ready ?? this.ready,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Product toggleReady() => copyWith(ready: !ready);

  int get margin => price - hpp;
}
