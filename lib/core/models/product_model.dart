import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/core/constants/countries.dart';

class Product {
  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.countryCode,
    required this.currencyCode,
    List<String>? imageUrls,
    required this.description,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerId,
    this.createdAt,
  }) : imageUrls = imageUrls ?? (imageUrl.isNotEmpty ? [imageUrl] : const <String>[]);

  final String id;
  final String title;
  final String category;
  final String location;
  final String price;
  final String countryCode;
  final String currencyCode;
  final String imageUrl;
  final List<String> imageUrls;
  final String description;
  final String sellerName;
  final String sellerPhone;
  final String sellerId;
  final DateTime? createdAt;

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? createdAt;
    final value = map['createdAt'];
    if (value is Timestamp) {
      createdAt = value.toDate();
    } else if (value is DateTime) {
      createdAt = value;
    }

    final fallbackImageUrl = map['imageUrl']?.toString() ?? '';
    final rawImageUrls = map['imageUrls'];
    final parsedImageUrls = <String>[];

    if (rawImageUrls is List) {
      for (final item in rawImageUrls) {
        final value = item?.toString();
        if (value != null && value.isNotEmpty) {
          parsedImageUrls.add(value);
        }
      }
    }

    final resolvedImageUrls = parsedImageUrls.isNotEmpty
        ? parsedImageUrls
        : (fallbackImageUrl.isNotEmpty ? [fallbackImageUrl] : <String>[]);

    final primaryImageUrl = resolvedImageUrls.isNotEmpty
        ? resolvedImageUrls.first
        : fallbackImageUrl;

    return Product(
      id: id ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? 'عام',
      location: map['location']?.toString() ?? '',
      price: map['price']?.toString() ?? '0',
      countryCode: map['countryCode']?.toString() ?? DealCountries.defaultCountryCode,
      currencyCode:
          map['currencyCode']?.toString() ??
          DealCountries.byCode(DealCountries.defaultCountryCode).currencyCode,
      imageUrl: primaryImageUrl,
      imageUrls: resolvedImageUrls,
      description: map['description']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? '',
      sellerPhone: map['sellerPhone']?.toString() ?? '',
      sellerId: map['sellerId']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final urls = <String>[];
    if (imageUrl.isNotEmpty && !urls.contains(imageUrl)) {
      urls.add(imageUrl);
    }
    for (final url in imageUrls) {
      if (url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }

    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'price': price,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'imageUrl': primaryImageUrl,
      'imageUrls': urls,
      'description': description,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerId': sellerId,
    };
  }
}
