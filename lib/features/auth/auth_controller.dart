import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../models/resto_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final profileProvider = FutureProvider<RestoProfile?>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Future.value(null);
  return _fetchProfile(uid);
});

Future<RestoProfile?> _fetchProfile(String uid) async {
  final doc = await FirebaseFirestore.instance
      .doc('users/$uid/profile/resto')
      .get();
  if (!doc.exists) return null;
  return RestoProfile.fromJson(doc.data()!);
}
