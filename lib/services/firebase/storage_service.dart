import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static FirebaseStorage get storage => FirebaseStorage.instance;

  static Future<String> uploadProductImage({required String folder, required XFile file}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = storage.ref().child(folder).child(fileName);
    final bytes = await file.readAsBytes();
    final uploadTask = await ref.putData(bytes);
    return uploadTask.ref.getDownloadURL();
  }

  static Future<List<String>> uploadProductImages({
    required String folder,
    required List<XFile> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadProductImage(folder: folder, file: file));
    }
    return urls;
  }

  static Future<void> deleteProductImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty || !imageUrl.contains('firebasestorage.googleapis.com')) {
      return;
    }

    try {
      final ref = storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Ignore deletion errors for images that are not stored in Firebase Storage.
    }
  }

  static Future<void> deleteProductImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      await deleteProductImage(imageUrl);
    }
  }
}
