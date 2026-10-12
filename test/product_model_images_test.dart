import 'package:deal/core/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product image handling', () {
    test('reads multiple image URLs from Firestore and keeps a primary image fallback', () {
      final product = Product.fromMap({
        'title': 'منضدة',
        'category': 'أثاث',
        'location': 'جدة',
        'price': '1200',
        'imageUrl': 'https://example.com/main.jpg',
        'imageUrls': ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
        'description': 'منتج جيد',
        'sellerName': 'مشتري',
        'sellerPhone': '966500000000',
        'sellerId': 'seller-1',
      }, id: 'p1');

      expect(product.imageUrl, 'https://example.com/1.jpg');
      expect(product.imageUrls, ['https://example.com/1.jpg', 'https://example.com/2.jpg']);
      expect(product.primaryImageUrl, 'https://example.com/1.jpg');
    });
  });
}
