import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firestore_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/resto_profile.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final uid = ref.watch(userIdProvider)!;
  final firestore = ref.watch(firestoreProvider);
  return SettingsRepository(firestore, uid);
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<RestoProfile?>>(
        (ref) {
  final profile = ref.watch(profileProvider);
  return ProfileNotifier(profile.valueOrNull);
});

class ProfileNotifier extends StateNotifier<AsyncValue<RestoProfile?>> {
  ProfileNotifier(RestoProfile? profile)
      : super(AsyncValue.data(profile));

  void update(RestoProfile p) => state = AsyncValue.data(p);
}
