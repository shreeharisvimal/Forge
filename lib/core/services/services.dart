// Service barrel for the Forge core layer.
//
// Import one library to reach every reusable service and engine. Feature
// code should prefer explicit per-file imports; the barrel exists for
// wiring, documentation and to keep the layer boundary obvious.
library;

export 'analytics/analytics_service.dart';
export 'backup/backup_engine.dart';
export 'clipboard/clipboard_service.dart';
export 'connectivity/connectivity_service.dart';
export 'data_bundle.dart';
export 'data_registry.dart';
export 'date_time/date_service.dart';
export 'device/device_service.dart';
export 'error_handling/forge_failures.dart';
export 'error_handling/global_error_handler.dart';
export 'error_handling/result.dart';
export 'export/export_engine.dart';
export 'file/file_service.dart';
export 'haptics/haptics_service.dart';
export 'images/image_service.dart';
export 'import/import_engine.dart';
export 'lifecycle/app_lifecycle_service.dart';
export 'logger/forge_logger.dart';
export 'notifications/notification_service.dart';
export 'permissions/permission_service.dart';
export 'search/search_engine.dart';
export 'share/share_service.dart';
export 'storage/preferences_store.dart';
export 'validation/validator.dart';
