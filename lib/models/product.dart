class Product {
  final String code;
  final String name;
  final double price;
  final int box;
  final double length;
  final double width;
  final double height;
  final double weight;
  final double inland;
  final double profit;
  final String link;
  final String image;

  Product({
    required this.code,
    required this.name,
    this.price = 0,
    this.box = 1,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.weight = 0,
    this.inland = 0,
    this.profit = 25,
    this.link = '',
    this.image = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      box: json['box'] ?? 1,
      length: (json['length'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      inland: (json['inland'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 25).toDouble(),
      link: json['link'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'price': price,
      'box': box,
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
      'inland': inland,
      'profit': profit,
      'link': link,
      'image': image,
    };
  }
}
