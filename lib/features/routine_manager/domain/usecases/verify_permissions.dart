import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';

part 'verify_permissions.g.dart';

/// Verify Permissions UseCase - Checks if the app has required OS permissions to run routines.
/// // Fulfills INT-09, Standard 3.1
@riverpod
Future<Result<bool, DomainError>> verifyPermissions(VerifyPermissionsRef ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  
  final hasPermissions = await notificationService.checkPermissions();
  
  if (hasPermissions) {
    return const Result.success(true);
  } else {
    return const Result.failure(DomainError.permissionDenied);
  }
}
