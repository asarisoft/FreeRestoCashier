import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resto_profile.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  SettingsRepository(this._firestore, this._uid);

  DocumentReference get _profileDoc =>
      _firestore.doc('users/$_uid/profile/resto');

  Future<void> updateProfile(RestoProfile profile) async {
    await _profileDoc.update(profile.toJson());
  }
}
