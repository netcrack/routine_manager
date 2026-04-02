import 'domain_error.dart';

/// A simple Result pattern implementation for standardizing UseCase returns.
/// // Fulfills Core Standards Section 5.1
class Result<S, F extends DomainError> {
  final S? _success;
  final F? _failure;

  const Result.success(S success)
      : _success = success,
        _failure = null;

  const Result.failure(F failure)
      : _success = null,
        _failure = failure;

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  S get success => _success!;
  F get failure => _failure!;

  void when({
    required void Function(S success) onSuccess,
    required void Function(F failure) onFailure,
  }) {
    if (isSuccess) {
      onSuccess(_success as S);
    } else {
      onFailure(_failure as F);
    }
  }

  T fold<T>(
    T Function(S success) onSuccess,
    T Function(F failure) onFailure,
  ) {
    if (isSuccess) {
      return onSuccess(_success as S);
    } else {
      return onFailure(_failure as F);
    }
  }
}
