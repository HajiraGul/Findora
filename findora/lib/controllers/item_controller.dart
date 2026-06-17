import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/item_model.dart';
import '../models/match_suggestion.dart';
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
  int _itemsRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems({
    String? category,
    String? status,
    String? q,
    String? color,
    String? fromDate,
    String? toDate,
  }) async {
    final requestId = ++_itemsRequestId;
    try {
      isLoading.value = true;
      final response = await _api.getItems(
        category: category,
        status: status,
        q: q,
        color: color,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (response.isOk && response.body is Map) {
        final list = (response.body['items'] as List?) ?? [];
        if (requestId == _itemsRequestId) {
          items.value = list
              .map((j) => ItemModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // keep previous state on network error
    } finally {
      if (requestId == _itemsRequestId) {
        isLoading.value = false;
      }
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
        if (myIdx != -1) {
          myItems[myIdx] = myItems[myIdx].copyWith(isResolved: true);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches scored match suggestions for one of the user's own posts. Returns
  /// the source item plus the ranked candidates, or null on failure.
  Future<({ItemModel source, List<MatchSuggestion> matches})?> fetchMatches(
    String itemId,
  ) async {
    if (_token.isEmpty) return null;
    try {
      final response = await _api.getMatches(token: _token, id: itemId);
      if (response.isOk && response.body is Map) {
        final sourceJson = response.body['sourceItem'];
        final list = (response.body['matches'] as List?) ?? [];
        if (sourceJson is! Map) return null;
        return (
          source: ItemModel.fromJson(sourceJson.cast<String, dynamic>()),
          matches: list
              .map((j) => MatchSuggestion.fromJson(j as Map<String, dynamic>))
              .toList(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Found-item owner nudges the lost-item owner that a match was spotted.
  Future<bool> notifyMatch({
    required String itemId,
    required String matchItemId,
  }) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.notifyMatch(
        token: _token,
        id: itemId,
        matchItemId: matchItemId,
      );
      return response.isOk;
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
