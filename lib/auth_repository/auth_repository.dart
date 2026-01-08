import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/auth_repository/models/server_credentials.dart';
import 'package:playcado/auth_repository/models/user.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/secure_storage_service.dart';

export 'models/models.dart';

class AuthRepository {
  AuthRepository({
    required JellyfinClientService jellyfinClient,
    required SecureStorageService secureStorage,
  }) : _jellyfinClientService = jellyfinClient,
       _secureStorage = secureStorage;
  final JellyfinClientService _jellyfinClientService;
  final SecureStorageService _secureStorage;

  JellyfinDart? get client => _jellyfinClientService.client;
  ServerCredentials? get currentCredentials =>
      _jellyfinClientService.credentials;
  bool get isLoggedIn => _jellyfinClientService.hasSession;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<List<ServerCredentials>> getSavedAccounts() async {
    return _secureStorage.getSavedAccounts();
  }

  void _clearSession() {
    _jellyfinClientService.clear();
    _currentUser = null;
  }

  Future<User> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberCredentials = false,
  }) async {
    LoggerService.auth.info(
      'Starting login on server: $serverUrl',
    );

    final trimmedUrl = serverUrl.trim();
    final hadNoScheme =
        !trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://');
    final effectiveServerUrl = hadNoScheme ? 'https://$trimmedUrl' : trimmedUrl;

    try {
      return await _attemptLogin(
        effectiveServerUrl: effectiveServerUrl,
        username: username,
        password: password,
        rememberCredentials: rememberCredentials,
      );
    } on DioException catch (e) {
      if (hadNoScheme && _isConnectionError(e)) {
        LoggerService.auth.info(
          'HTTPS connection failed, retrying with HTTP',
        );
        try {
          return await _attemptLogin(
            effectiveServerUrl: 'http://$trimmedUrl',
            username: username,
            password: password,
            rememberCredentials: rememberCredentials,
          );
        } on Exception {
          _clearSession();
          rethrow;
        }
      }
      _clearSession();
      rethrow;
    } on Exception {
      _clearSession();
      rethrow;
    }
  }

  Future<User> _attemptLogin({
    required String effectiveServerUrl,
    required String username,
    required String password,
    required bool rememberCredentials,
  }) async {
    final newClient = JellyfinDart(
      basePathOverride: effectiveServerUrl,
    );

    final deviceId = 'playcado-${DateTime.now().millisecondsSinceEpoch}';

    newClient.setMediaBrowserAuth(
      deviceId: deviceId,
      version: '1.0.0',
      client: 'playcado',
      device: 'Playcado App',
    );

    final userApi = newClient.getUserApi();
    final authRequest = AuthenticateUserByName(
      username: username,
      pw: password,
    );
    final response = await userApi.authenticateUserByName(
      authenticateUserByName: authRequest,
    );
    final authenticationResult = response.data;

    final user = authenticationResult?.user;
    final token = authenticationResult?.accessToken;
    final userId = user?.id;

    if (user != null && token != null && userId != null) {
      LoggerService.auth.info('Authentication successful');
      newClient.setToken(token);

      final credentials = ServerCredentials(
        serverName: effectiveServerUrl,
        username: username,
        password: password,
        accessToken: token,
      );

      _jellyfinClientService.setClient(
        newClient,
        credentials,
        token,
        deviceId,
      );

      _currentUser = User(
        id: userId,
        name: user.name ?? '',
        accessToken: token,
      );

      if (rememberCredentials) {
        LoggerService.auth.info('Saving credentials securely (token-based)');
        await _secureStorage.storeCredentials(credentials);
        await _secureStorage.saveAccount(credentials);
      }
      return _currentUser!;
    }

    LoggerService.auth.warning('Authentication returned null result/token');
    throw Exception('Authentication returned null result or token');
  }

  bool _isConnectionError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  Future<User> loginWithToken({
    required String serverUrl,
    required String username,
    required String token,
  }) async {
    LoggerService.auth.info(
      'Attempting to restore session on server: $serverUrl',
    );
    try {
      var effectiveServerUrl = serverUrl.trim();
      if (!effectiveServerUrl.startsWith('http://') &&
          !effectiveServerUrl.startsWith('https://')) {
        effectiveServerUrl = 'https://$effectiveServerUrl';
      }

      final newClient = JellyfinDart(
        basePathOverride: effectiveServerUrl,
      );
      final deviceId = 'playcado-${DateTime.now().millisecondsSinceEpoch}';

      newClient
        ..setMediaBrowserAuth(
          deviceId: deviceId,
          version: '1.0.0',
          client: 'playcado',
          device: 'Playcado App',
        )
        ..setToken(token);

      final userApi = newClient.getUserApi();
      final response = await userApi.getCurrentUser();
      final jellyfinUser = response.data;

      final userId = jellyfinUser?.id;

      if (jellyfinUser != null && userId != null) {
        LoggerService.auth.info('Session restored successfully');
        final credentials = ServerCredentials(
          serverName: effectiveServerUrl,
          username: username,
          accessToken: token,
        );

        _jellyfinClientService.setClient(
          newClient,
          credentials,
          token,
          deviceId,
        );

        _currentUser = User(
          id: userId,
          name: jellyfinUser.name ?? '',
          accessToken: token,
        );

        await _secureStorage.storeCredentials(credentials);
        await _secureStorage.saveAccount(credentials);

        return _currentUser!;
      }

      LoggerService.auth.warning(
        'Token verification failed — token may be expired',
      );
      _clearSession();
      await _secureStorage.clearCredentials();
      throw Exception('Token verification failed — token may be expired');
    } on Exception catch (e) {
      LoggerService.auth.severe(
        'Token login failed',
        e,
      );
      _clearSession();

      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        LoggerService.auth.warning(
          'Token rejected by server, clearing credentials',
        );
        await _secureStorage.clearCredentials();
      } else {
        LoggerService.auth.warning(
          'Network or server error during token '
          'verification, keeping credentials',
        );
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    LoggerService.auth.info('Logging out user');
    _jellyfinClientService.clear();
    _currentUser = null;
    await _secureStorage.clearCredentials();
  }

  Future<void> removeAccount(String id) async {
    LoggerService.auth.info('Removing saved account: $id');
    await _secureStorage.removeAccount(id);
  }

  Future<User?> tryAutoLogin() async {
    try {
      final storedCredentials = await _secureStorage.retrieveCredentials();
      if (storedCredentials == null || storedCredentials.accessToken == null) {
        return null;
      }
      LoggerService.auth.info(
        'Found stored credentials for '
        '${storedCredentials.username}, attempting login',
      );
      return await loginWithToken(
        serverUrl: storedCredentials.serverName,
        username: storedCredentials.username,
        token: storedCredentials.accessToken!,
      );
    } on Exception catch (e) {
      LoggerService.auth.warning('Auto-login failed', e);
      return null;
    }
  }

  /// Sets the current user manually. Useful for demo mode.
  // ignore: use_setters_to_change_properties
  void setDemoUser(User user) {
    _currentUser = user;
  }
}
