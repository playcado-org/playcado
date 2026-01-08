part of 'server_management_bloc.dart';

class ServerManagementState extends Equatable {
  const ServerManagementState({
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.accessToken,
    this.isLoading = false,
  });
  final String serverUrl;
  final String username;
  final String password;
  final String? accessToken;
  final bool isLoading;

  ServerManagementState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? accessToken,
    bool? isLoading,
  }) {
    return ServerManagementState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    serverUrl,
    username,
    password,
    accessToken,
    isLoading,
  ];
}
