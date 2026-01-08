import 'package:equatable/equatable.dart';

sealed class StatusWrapper<T> extends Equatable {
  const StatusWrapper();

  /// Convenience getters for checking state type.
  bool get isInitial => this is StatusInitial<T>;
  bool get isLoading => this is StatusLoading<T>;
  bool get isSuccess => this is StatusSuccess<T>;
  bool get isError => this is StatusError<T>;

  /// Returns the value if available, regardless of state.
  /// Success always has a value. Loading and Error may retain a previous value.
  T? get value => switch (this) {
    StatusSuccess(:final value) => value,
    StatusLoading(:final previousValue) => previousValue,
    StatusError(:final previousValue) => previousValue,
    StatusInitial() => null,
  };

  /// Returns the error message if in error state, null otherwise.
  String? get errorMessage => switch (this) {
    StatusError(:final message) => message,
    _ => null,
  };
}

final class StatusInitial<T> extends StatusWrapper<T> {
  const StatusInitial();

  @override
  List<Object?> get props => [];
}

final class StatusLoading<T> extends StatusWrapper<T> {
  const StatusLoading({this.previousValue});
  final T? previousValue;

  @override
  List<Object?> get props => [previousValue];
}

final class StatusSuccess<T> extends StatusWrapper<T> {
  const StatusSuccess(this.value);
  @override
  final T value;

  @override
  List<Object?> get props => [value];
}

final class StatusError<T> extends StatusWrapper<T> {
  const StatusError(this.message, {this.previousValue});
  final String message;
  final T? previousValue;

  @override
  List<Object?> get props => [message, previousValue];
}
