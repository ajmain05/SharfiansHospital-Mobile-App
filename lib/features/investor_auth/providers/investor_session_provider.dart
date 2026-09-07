import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../models/investor.dart';
import '../data/investor_repository.dart';
import '../../../core/services/push_notification_service.dart';

class InvestorSessionState {
  final List<Investor> accounts;
  final String? activeAccountId;
  final bool isLoading;
  final String? error;

  const InvestorSessionState({
    this.accounts = const [],
    this.activeAccountId,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => accounts.isNotEmpty;

  Investor? get activeAccount {
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.id == activeAccountId,
      orElse: () => accounts.first,
    );
  }

  InvestorSessionState copyWith({
    List<Investor>? accounts,
    String? activeAccountId,
    bool? isLoading,
    String? error,
  }) {
    return InvestorSessionState(
      accounts: accounts ?? this.accounts,
      activeAccountId: activeAccountId ?? this.activeAccountId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Holds the logged-in investor's accounts (a phone number can match several,
/// e.g. family members) and which one is currently active. Restores instantly
/// from the cached raw payload on app start, then silently refreshes —
/// the same pattern as the website's `InvestorDashboard.jsx`.
class InvestorSessionNotifier extends StateNotifier<InvestorSessionState> {
  final InvestorRepository _repo;
  final PushNotificationService _pushService;

  InvestorSessionNotifier(this._repo, this._pushService) : super(const InvestorSessionState()) {
    _restoreFromCache();
  }

  void _restoreFromCache() {
    final cached = LocalStorage.getInvestorAccounts();
    final token = LocalStorage.getInvestorToken();
    // A session cached before login started issuing tokens has accounts but
    // no token — it can never pass the backend's investorAuth check again,
    // so treat it the same as logged out rather than showing stale data
    // forever behind a silent refresh that will just keep failing quietly.
    if (cached == null || cached.isEmpty || token == null) return;
    final accounts = cached.map(Investor.fromJson).toList();
    state = state.copyWith(
      accounts: accounts,
      activeAccountId: accounts.first.id,
    );
    _silentRefresh();
  }

  Future<void> _silentRefresh() async {
    if (LocalStorage.getInvestorToken() == null) return;
    try {
      final raw = await _repo.loginWithPhone();
      if (raw.isNotEmpty) {
        await LocalStorage.saveInvestorAccounts(raw);
        final accounts = raw.map(Investor.fromJson).toList();
        final keepActive =
            state.activeAccountId != null &&
            accounts.any((a) => a.id == state.activeAccountId);
        state = state.copyWith(
          accounts: accounts,
          activeAccountId: keepActive
              ? state.activeAccountId
              : accounts.first.id,
        );
      }
    } on ApiException catch (e) {
      // An expired/invalid session token (401/403) means the cached data can
      // never actually refresh again until they log back in — unlike a
      // plain network hiccup, silently keeping the stale cache forever would
      // leave them stuck with no way back to the login screen.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logout();
      }
    } catch (_) {
      // Keep showing cached data if the silent refresh fails for any other
      // reason (offline, server hiccup).
    }
  }

  /// Explicit-login entry point (OTP-gated for BD numbers). Returns
  /// `otpRequired: true` when [verifyOtpAndLogin] must be called next;
  /// `otpRequired: false` means login is already complete (non-BD number),
  /// identical in effect to [loginWithPhone].
  Future<({bool otpRequired, bool loggedIn})> startPhoneAuth(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.startPhoneAuth(phone);
      if (result.otpRequired) {
        state = state.copyWith(isLoading: false);
        return (otpRequired: true, loggedIn: false);
      }
      if (result.accounts.isEmpty) {
        state = state.copyWith(isLoading: false);
        return (otpRequired: false, loggedIn: false);
      }
      await _applyLoggedInAccounts(result.accounts, phone, result.token);
      return (otpRequired: false, loggedIn: true);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.statusCode == 404 ? null : e.message);
      return (otpRequired: false, loggedIn: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return (otpRequired: false, loggedIn: false);
    }
  }

  /// Verifies the code sent by [startPhoneAuth] and completes login.
  /// Returns true on success, false on a wrong/expired code.
  Future<bool> verifyOtpAndLogin(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.verifyPhoneAuthOtp(phone, code);
      if (result.accounts.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _applyLoggedInAccounts(result.accounts, phone, result.token);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _applyLoggedInAccounts(
    List<Map<String, dynamic>> raw,
    String phone,
    String? token,
  ) async {
    await LocalStorage.saveInvestorAccounts(raw);
    await LocalStorage.saveInvestorPhone(phone);
    // Always present in practice (issued by both /auth-phone/start's non-BD
    // branch and /auth-phone/verify) — the null case only guards against a
    // stale/mismatched backend response shape rather than being an expected
    // path, so this deliberately doesn't clear a session that already works.
    if (token != null) await LocalStorage.saveInvestorToken(token);
    final accounts = raw.map(Investor.fromJson).toList();
    state = InvestorSessionState(
      accounts: accounts,
      activeAccountId: accounts.first.id,
    );
    _pushService.registerToken(phone: phone);
  }

  Future<void> refresh() => _silentRefresh();

  void setActiveAccount(String id) {
    state = state.copyWith(activeAccountId: id);
  }

  Future<void> updateActiveAccountProfile(Map<String, dynamic> updated) async {
    final accounts = state.accounts
        .map((a) => a.id == updated['id'] ? Investor.fromJson(updated) : a)
        .toList();
    final raw = LocalStorage.getInvestorAccounts() ?? [];
    final newRaw = raw
        .map((j) => j['id'] == updated['id'] ? updated : j)
        .toList();
    await LocalStorage.saveInvestorAccounts(newRaw);
    state = state.copyWith(accounts: accounts);
  }

  Future<void> logout() async {
    await _pushService.detachToken(clearPhone: true);
    await LocalStorage.clearInvestorSession();
    state = const InvestorSessionState();
  }
}

final investorRepositoryProvider = Provider<InvestorRepository>(
  (ref) => InvestorRepository(),
);

final investorSessionProvider =
    StateNotifierProvider<InvestorSessionNotifier, InvestorSessionState>((ref) {
      return InvestorSessionNotifier(
        ref.watch(investorRepositoryProvider),
        ref.watch(pushNotificationServiceProvider),
      );
    });
