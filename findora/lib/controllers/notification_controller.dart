import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

class NotificationController extends GetxController {
  final NotificationApiService _api;

  NotificationController(this._api);

  String get _token => Get.find<AuthController>().token.value ?? '';

  final notifications = <AppNotification>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  Future<void> fetch() async {
    if (_token.isEmpty) return;
    try {
      isLoading.value = true;
      final response = await _api.getNotifications(_token);
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] ?? response.body['notifications']) as List? ?? [];
        notifications.value = list
            .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
            .toList();
        final unread = response.body['unreadCount'];
        if (unread is num) unreadCount.value = unread.toInt();
      }
    } catch (_) {
      // keep previous state on network error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_token.isEmpty) return;
    try {
      final response = await _api.getUnreadCount(_token);
      if (response.isOk && response.body is Map) {
        final unread = response.body['unreadCount'];
        if (unread is num) unreadCount.value = unread.toInt();
      }
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || notifications[idx].isRead) return;

    // Optimistic update — the row dims and the badge drops immediately.
    notifications[idx] = notifications[idx].copyWith(isRead: true);
    if (unreadCount.value > 0) unreadCount.value -= 1;

    if (_token.isEmpty) return;
    try {
      await _api.markRead(_token, id);
    } catch (_) {
      // Best-effort; the next fetch reconciles state.
    }
  }

  Future<void> markAllRead() async {
    notifications.value =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    unreadCount.value = 0;

    if (_token.isEmpty) return;
    try {
      await _api.markAllRead(_token);
    } catch (_) {}
  }

  void clear() {
    notifications.clear();
    unreadCount.value = 0;
  }
}
