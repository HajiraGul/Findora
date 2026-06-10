import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/claim_model.dart';
import '../services/claim_api_service.dart';

class ClaimController extends GetxController {
  final ClaimApiService _api;

  ClaimController(this._api);

  String get _token => Get.find<AuthController>().token.value ?? '';

  final claims = <ClaimModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  Future<void> fetchMyClaims({String? status}) async {
    if (_token.isEmpty) return;
    try {
      isLoading.value = true;
      final response = await _api.getMyClaims(token: _token, status: status);
      if (response.isOk && response.body is Map) {
        final list = (response.body['claims'] as List?) ?? [];
        claims.value = list
            .map((j) => ClaimModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // keep previous state on network error
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitClaim(Map<String, dynamic> data) async {
    if (_token.isEmpty) return false;
    try {
      isSubmitting.value = true;
      final response = await _api.submitClaim(token: _token, data: data);
      final ok = response.statusCode == 201 || response.isOk;
      if (ok) fetchMyClaims();
      return ok;
    } catch (_) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> approveClaim(String id, {String? adminNote}) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.approveClaim(
        token: _token,
        id: id,
        adminNote: adminNote,
      );
      if (response.isOk) {
        _updateLocalStatus(id, ClaimStatus.approved);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectClaim(String id, {String? adminNote}) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.rejectClaim(
        token: _token,
        id: id,
        adminNote: adminNote,
      );
      if (response.isOk) {
        _updateLocalStatus(id, ClaimStatus.rejected);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _updateLocalStatus(String id, ClaimStatus newStatus) {
    final idx = claims.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final old = claims[idx];
    claims[idx] = ClaimModel(
      id: old.id,
      itemId: old.itemId,
      itemTitle: old.itemTitle,
      itemCategory: old.itemCategory,
      claimantId: old.claimantId,
      claimantName: old.claimantName,
      status: newStatus,
      createdAt: old.createdAt,
      adminNote: old.adminNote,
      proofType: old.proofType,
      answers: old.answers,
    );
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
