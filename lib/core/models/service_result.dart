import 'package:ireader/core/models/app_failure.dart';

class ServiceResult<T> {
  final T? data;
  final AppFailure? failure;

  const ServiceResult._({this.data, this.failure});

  bool get isSuccess => data != null && failure == null;

  T get requireData {
    if (!isSuccess || data == null) {
      throw StateError('ServiceResult does not contain data.');
    }
    return data as T;
  }

  static ServiceResult<T> success<T>(T data) {
    return ServiceResult<T>._(data: data);
  }

  static ServiceResult<T> error<T>(AppFailure failure) {
    return ServiceResult<T>._(failure: failure);
  }
}
