import 'package:equatable/equatable.dart';

class ServerCredentials extends Equatable {
  const ServerCredentials({
    required this.serverName,
    required this.username,
    this.password,
    this.accessToken,
  });

  factory ServerCredentials.fromMap(Map<String, dynamic> map) {
    return ServerCredentials(
      serverName: (map['serverName'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      password: map['password'] as String?,
      accessToken: map['accessToken'] as String?,
    );
  }

  final String serverName;
  final String username;
  final String? password;
  final String? accessToken;

  /// Unique identifier for this credential set
  String get id => '$username@$serverName';

  Map<String, dynamic> toMap() {
    return {
      'serverName': serverName,
      'username': username,
      if (password != null) 'password': password,
      if (accessToken != null) 'accessToken': accessToken,
    };
  }

  @override
  String toString() {
    return 'ServerCredentials('
        'serverName: $serverName, '
        'username: $username, '
        'hasToken: ${accessToken != null})';
  }

  @override
  List<Object?> get props => [serverName, username, password, accessToken];
}
