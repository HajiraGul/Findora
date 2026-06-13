import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/claim_controller.dart';
import '../controllers/item_controller.dart';
import '../services/admin_api_service.dart';
import '../services/auth_api_service.dart';
import '../services/chat_api_service.dart';
import '../services/claim_api_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_chat_service.dart';
import '../services/item_api_service.dart';
import '../services/push_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthApiService>(() => AuthApiService(), fenix: true);
    Get.lazyPut<ItemApiService>(() => ItemApiService(), fenix: true);
    Get.lazyPut<ClaimApiService>(() => ClaimApiService(), fenix: true);
    Get.lazyPut<ChatApiService>(() => ChatApiService(), fenix: true);
    Get.lazyPut<AdminApiService>(() => AdminApiService(), fenix: true);
    Get.lazyPut<FirebaseAuthService>(() => FirebaseAuthService(), fenix: true);
    Get.lazyPut<PushService>(() => PushService(), fenix: true);
    Get.lazyPut<FirestoreChatService>(
      () => FirestoreChatService(),
      fenix: true,
    );
    // Permanent + eager: the restored login session must live for the whole
    // app lifetime. With lazyPut + SmartManagement.full it was disposed on
    // route changes and recreated with a null token, bouncing the user back
    // to the login screen after a hot reload / navigation.
    Get.put<AuthController>(
      AuthController(
        Get.find<AuthApiService>(),
        Get.find<FirebaseAuthService>(),
        Get.find<PushService>(),
      ),
      permanent: true,
    );
    Get.lazyPut<ItemController>(
      () => ItemController(Get.find<ItemApiService>()),
      fenix: true,
    );
    Get.lazyPut<ClaimController>(
      () => ClaimController(Get.find<ClaimApiService>()),
      fenix: true,
    );
    Get.lazyPut<ChatController>(
      () => ChatController(
        Get.find<ChatApiService>(),
        Get.find<FirestoreChatService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<AdminController>(
      () => AdminController(
        Get.find<AdminApiService>(),
        Get.find<ClaimApiService>(),
        Get.find<ItemApiService>(),
      ),
      fenix: true,
    );
  }
}
