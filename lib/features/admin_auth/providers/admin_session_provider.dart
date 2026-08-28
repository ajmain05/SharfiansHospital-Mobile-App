import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/services/push_notification_service.dart';
import '../data/admin_repository.dart';

class AdminSessionState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AdminSessionState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;

  AdminSessionState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
  }) {
    return AdminSessionState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminSessionNotifier extends StateNotifier<AdminSessionState> {
  final AdminRepository _repo;
  final PushNotificationService _pushService;

  AdminSessionNotifier(this._repo, this._pushService) : super(const AdminSessionState()) {
    _restoreFromCache();
  }

  void _restoreFromCache() {
    final cached = LocalStorage.getAdminData();
    if (cached != null) {
      state = state.copyWith(user: cached);
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    final token = LocalStorage.getAdminToken();
    if (token == null) return;
    try {
      final user = await _repo.getMe();
      await LocalStorage.saveAdminData(user);
      state = state.copyWith(user: user);
    } catch (_) {
      // If fetching me fails (e.g., token invalid), we should probably logout.
      // We'll let explicit API calls fail normally though.
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.login(email, password);
      final token = res['token'] as String;
      final user = res['user'] as Map<String, dynamic>;
      
      await LocalStorage.saveAdminToken(token);
      await LocalStorage.saveAdminData(user);
      
      // Register FCM token for this admin user
      _pushService.registerToken(userId: user['id']);
      
      state = AdminSessionState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _pushService.detachToken(clearUserId: true);
    await LocalStorage.clearAdminSession();
    state = const AdminSessionState();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminSessionProvider =
    StateNotifierProvider<AdminSessionNotifier, AdminSessionState>((ref) {
  return AdminSessionNotifier(
    ref.watch(adminRepositoryProvider),
    ref.watch(pushNotificationServiceProvider),
  );
});
