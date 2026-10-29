class MarketplaceItemModel {
  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final num price;
  final String currency;
  final List<String> imageUrls;
  final String? category;
  final String status; // 'available', 'reserved', 'sold'
  final String createdAt;

  MarketplaceItemModel({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'UGX',
    this.imageUrls = const [],
    this.category,
    this.status = 'available',
    required this.createdAt,
  });

  factory MarketplaceItemModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['image_urls'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    return MarketplaceItemModel(
      id: json['id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: json['price'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'UGX',
      imageUrls: images,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'available',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'image_urls': imageUrls,
      'category': category,
      'status': status,
    };
  }
}
