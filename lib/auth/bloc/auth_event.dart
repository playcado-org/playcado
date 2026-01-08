part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthLoadAccountsRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested(
    this.server,
    this.username,
    this.password, {
    this.rememberCredentials = true,
  });
  final String server;
  final String username;
  final String password;
  final bool rememberCredentials;

  @override
  List<Object> get props => [server, username, password, rememberCredentials];
}

class AuthLogoutRequested extends AuthEvent {
  AuthLogoutRequested();
}

class AuthRemoveAccountRequested extends AuthEvent {
  AuthRemoveAccountRequested(this.id);
  final String id;

  @override
  List<Object> get props => [id];
}

class AuthSwitchAccountRequested extends AuthEvent {
  AuthSwitchAccountRequested(this.credentials);
  final ServerCredentials credentials;

  @override
  List<Object> get props => [credentials];
}

class AuthEnterOfflineModeRequested extends AuthEvent {}

class AuthDemoModeRequested extends AuthEvent {}
