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
    if (cached == null || cached.isEmpty) return;
    final accounts = cached.map(Investor.fromJson).toList();
    state = state.copyWith(
      accounts: accounts,
      activeAccountId: accounts.first.id,
    );
    _silentRefresh();
  }

  Future<void> _silentRefresh() async {
    final phone = LocalStorage.getInvestorPhone();
    if (phone == null) return;
    try {
      final raw = await _repo.loginWithPhone(phone);
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
    } catch (_) {
      // Keep showing cached data if the silent refresh fails.
    }
  }

  /// Returns true on success, false if no account matched the phone.
  Future<bool> loginWithPhone(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final raw = await _repo.loginWithPhone(phone);
      if (raw.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _applyLoggedInAccounts(raw, phone);
      return true;
    } on ApiException catch (e) {
      // A genuine "no such account" (404) leaves error null so the screen
      // falls back to its own localized "no account found" text; anything
      // else (network/server issue) surfaces here so the screen doesn't
      // tell a real investor their account doesn't exist when the actual
      // problem was connectivity or server load.
      state = state.copyWith(isLoading: false, error: e.statusCode == 404 ? null : e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
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
      await _applyLoggedInAccounts(result.accounts, phone);
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
      final raw = await _repo.verifyPhoneAuthOtp(phone, code);
      if (raw.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _applyLoggedInAccounts(raw, phone);
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
  ) async {
    await LocalStorage.saveInvestorAccounts(raw);
    await LocalStorage.saveInvestorPhone(phone);
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
