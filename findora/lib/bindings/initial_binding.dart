import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../services/auth_api_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthApiService>(() => AuthApiService(), fenix: true);
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthApiService>()),
      fenix: true,
    );
  }
}
