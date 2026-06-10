import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/item_model.dart';
import '../services/item_api_service.dart';

class ItemController extends GetxController {
  final ItemApiService _api;

  ItemController(this._api);

  String get _token => Get.find<AuthController>().token.value ?? '';

  final items = <ItemModel>[].obs;
  final myItems = <ItemModel>[].obs;
  final nearbyItems = <ItemModel>[].obs;
  final isLoading = false.obs;
  final myItemsLoading = false.obs;
  final nearbyLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems({
    String? category,
    String? status,
    String? q,
  }) async {
    try {
      isLoading.value = true;
      final response = await _api.getItems(
        category: category,
        status: status,
        q: q,
      );
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] as List?) ?? [];
        items.value = list
            .map((j) => ItemModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // keep previous state on network error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyItems() async {
    if (_token.isEmpty) return;
    try {
      myItemsLoading.value = true;
      final response = await _api.getMyItems(_token);
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] as List?) ?? [];
        myItems.value = list
            .map((j) => ItemModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      myItemsLoading.value = false;
    }
  }

  Future<void> fetchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
    String sort = 'distance',
  }) async {
    try {
      nearbyLoading.value = true;
      final response = await _api.getNearbyItems(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        sort: sort,
      );
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] as List?) ?? [];
        nearbyItems.value = list
            .map((j) => ItemModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      nearbyLoading.value = false;
    }
  }

  Future<bool> createItem(Map<String, dynamic> data) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.createItem(token: _token, data: data);
      final ok = response.statusCode == 201 || response.isOk;
      if (ok) fetchItems();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMyItem(String id) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.deleteItem(token: _token, id: id);
      if (response.isOk) {
        myItems.removeWhere((i) => i.id == id);
        items.removeWhere((i) => i.id == id);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveItem(String id) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.resolveItem(token: _token, id: id);
      if (response.isOk) {
        final idx = items.indexWhere((i) => i.id == id);
        if (idx != -1) items[idx] = items[idx].copyWith(isResolved: true);
        final myIdx = myItems.indexWhere((i) => i.id == id);
        if (myIdx != -1) myItems[myIdx] = myItems[myIdx].copyWith(isResolved: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('\n');
      }
      final message = body['message'];
      if (message != null) return message.toString();
    }
    return 'Something went wrong. Please try again.';
  }
}
