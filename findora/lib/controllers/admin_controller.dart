import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_user.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../services/admin_api_service.dart';
import '../services/claim_api_service.dart';
import '../services/item_api_service.dart';

class AdminStats {
  final int pendingClaims;
  final int activePosts;
  final int totalUsers;
  final int totalClaims;

  const AdminStats({
    this.pendingClaims = 0,
    this.activePosts = 0,
    this.totalUsers = 0,
    this.totalClaims = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      pendingClaims: _toInt(json['pendingClaims']),
      activePosts: _toInt(json['activePosts']),
      totalUsers: _toInt(json['totalUsers']),
      totalClaims: _toInt(json['totalClaims']),
    );
  }

  static int _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class AdminController extends GetxController {
  final AdminApiService _api;
  final ClaimApiService _claimApi;
  final ItemApiService _itemApi;

  AdminController(this._api, this._claimApi, this._itemApi);

  String get _token => Get.find<AuthController>().token.value ?? '';

  final stats = const AdminStats().obs;
  final users = <AuthUser>[].obs;
  final allClaims = <ClaimModel>[].obs;
  final allItems = <ItemModel>[].obs;

  final statsLoading = false.obs;
  final usersLoading = false.obs;
  final claimsLoading = false.obs;
  final itemsLoading = false.obs;

  Future<void> fetchStats() async {
    if (_token.isEmpty) return;
    try {
      statsLoading.value = true;
      final response = await _api.getStats(_token);
      if (response.isOk && response.body is Map) {
        final s = response.body['stats'];
        if (s is Map<String, dynamic>) {
          stats.value = AdminStats.fromJson(s);
        }
      }
    } catch (_) {
    } finally {
      statsLoading.value = false;
    }
  }

  Future<void> fetchUsers({String? q}) async {
    if (_token.isEmpty) return;
    try {
      usersLoading.value = true;
      final response = await _api.getUsers(token: _token, q: q);
      if (response.isOk && response.body is Map) {
        final list = (response.body['users'] as List?) ?? [];
        users.value = list
            .map((j) => AuthUser.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      usersLoading.value = false;
    }
  }

  Future<bool> banUser(String userId) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.banUser(token: _token, userId: userId);
      if (response.isOk) {
        _updateUserBanned(userId, banned: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unbanUser(String userId) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.unbanUser(token: _token, userId: userId);
      if (response.isOk) {
        _updateUserBanned(userId, banned: false);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.deleteUser(token: _token, userId: userId);
      if (response.isOk) {
        users.removeWhere((u) => u.id == userId);
        stats.value = AdminStats(
          pendingClaims: stats.value.pendingClaims,
          activePosts: stats.value.activePosts,
          totalUsers: (stats.value.totalUsers - 1).clamp(0, 999999),
          totalClaims: stats.value.totalClaims,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchAllClaims({String? status}) async {
    if (_token.isEmpty) return;
    try {
      claimsLoading.value = true;
      final response = await _claimApi.getAllClaims(
        token: _token,
        status: status,
      );
      if (response.isOk && response.body is Map) {
        final list = (response.body['claims'] as List?) ?? [];
        allClaims.value = list
            .map((j) => ClaimModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      claimsLoading.value = false;
    }
  }

  Future<void> fetchAllItems() async {
    if (_token.isEmpty) return;
    try {
      itemsLoading.value = true;
      final response = await _itemApi.getItems(limit: 50);
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] as List?) ?? [];
        allItems.value = list
            .map((j) => ItemModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      itemsLoading.value = false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    if (_token.isEmpty) return false;
    try {
      final response =
          await _itemApi.deleteItem(token: _token, id: itemId);
      if (response.isOk) {
        allItems.removeWhere((i) => i.id == itemId);
        stats.value = AdminStats(
          pendingClaims: stats.value.pendingClaims,
          activePosts: (stats.value.activePosts - 1).clamp(0, 999999),
          totalUsers: stats.value.totalUsers,
          totalClaims: stats.value.totalClaims,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _updateUserBanned(String userId, {required bool banned}) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx == -1) return;
    final old = users[idx];
    users[idx] = AuthUser(
      id: old.id,
      fullName: old.fullName,
      email: old.email,
      phone: old.phone,
      cityOrUniversity: old.cityOrUniversity,
      role: old.role,
      isEmailVerified: old.isEmailVerified,
      avatarUrl: old.avatarUrl,
      about: old.about,
      notifications: old.notifications,
      darkMode: old.darkMode,
      twoFactor: old.twoFactor,
      biometric: old.biometric,
      banned: banned,
    );
  }
}
