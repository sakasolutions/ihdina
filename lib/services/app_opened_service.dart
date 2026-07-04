import '../data/api/ihdina_api_client.dart';
import 'install_id_service.dart';

/// Meldet App-Start an `POST /api/v1/app-opened` (fire-and-forget, Fehler werden ignoriert).
class AppOpenedService {
  AppOpenedService._();

  static Future<void> recordAppOpened() async {
    try {
      final client = IhdinaApiClient.instance;
      if (!client.isConfigured) return;
      final installId = await InstallIdService.instance.getOrCreate();
      await client.postAppOpened(installId: installId);
    } catch (_) {}
  }
}
