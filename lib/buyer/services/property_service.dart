import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/firestore_service.dart';

class PropertyService {
  static Future<List<Product>> getProperties() async {
    final snapshot = await FirestoreService.getListings();

    return snapshot.docs
        .map(
          (doc) => Product.fromMap(
            doc.data(),
            id: doc.id,
          ),
        )
        .toList();
  }
}