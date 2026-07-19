import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<XFile?> pickImage() async {
    return ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
  }

  Future<String> upload(String uid, String productId, XFile file) async {
    final ref = _storage.ref('users/$uid/products/$productId.jpg');
    final task = await ref.putFile(File(file.path));
    return await task.ref.getDownloadURL();
  }

  Future<void> delete(String uid, String productId) async {
    try {
      await _storage.ref('users/$uid/products/$productId.jpg').delete();
    } catch (_) {}
  }
}
