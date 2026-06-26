part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState({
    this.availableAccounts = const [],
    this.user = const StatusInitial(),
    this.isDemoMode = false,
    this.credentials,
  });
  final List<ServerCredentials> availableAccounts;
  final StatusWrapper<User> user;
  final bool isDemoMode;
  final ServerCredentials? credentials;

  /// Returns true if the user is successfully authenticated.
  bool get isLoggedIn => user.isSuccess;

  AuthState copyWith({
    List<ServerCredentials>? availableAccounts,
    StatusWrapper<User>? user,
    bool? isDemoMode,
    ValueGetter<ServerCredentials?>? credentials,
  }) {
    return AuthState(
      availableAccounts: availableAccounts ?? this.availableAccounts,
      user: user ?? this.user,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      credentials: credentials != null ? credentials() : this.credentials,
    );
  }

  @override
  List<Object?> get props => [availableAccounts, user, isDemoMode, credentials];
}
