import 'package:equatable/equatable.dart';

import '../errors/failure.dart';

sealed class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ErrorResult<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        _ => null,
      };

  Failure? get failureOrNull => switch (this) {
        ErrorResult<T>(:final failure) => failure,
        _ => null,
      };
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
