import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/claim_controller.dart';
import '../controllers/item_controller.dart';
import '../services/auth_api_service.dart';
import '../services/claim_api_service.dart';
import '../services/item_api_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthApiService>(() => AuthApiService(), fenix: true);
    Get.lazyPut<ItemApiService>(() => ItemApiService(), fenix: true);
    Get.lazyPut<ClaimApiService>(() => ClaimApiService(), fenix: true);
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthApiService>()),
      fenix: true,
    );
    Get.lazyPut<ItemController>(
      () => ItemController(Get.find<ItemApiService>()),
      fenix: true,
    );
    Get.lazyPut<ClaimController>(
      () => ClaimController(Get.find<ClaimApiService>()),
      fenix: true,
    );
  }
}
