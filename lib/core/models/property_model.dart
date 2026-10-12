class Property {
  const Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.sellerName,
    required this.sellerPhone,
  });

  final String id;
  final String title;
  final String location;
  final String price;
  final String imageUrl;
  final String description;
  final String sellerName;
  final String sellerPhone;
}
