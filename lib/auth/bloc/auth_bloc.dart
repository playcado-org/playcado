import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/auth_repository/auth_repository.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/services/logger_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository, User? initialUser})
    : _authRepository = authRepository,
      super(
        AuthState(
          user: initialUser != null
              ? StatusSuccess<User>(initialUser)
              : const StatusInitial(),
          credentials: authRepository.currentCredentials,
        ),
      ) {
    on<AuthLoadAccountsRequested>(_onAuthLoadAccountsRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthRemoveAccountRequested>(_onAuthRemoveAccountRequested);
    on<AuthSwitchAccountRequested>(_onAuthSwitchAccountRequested);
    on<AuthDemoModeRequested>(_onAuthDemoModeRequested);

    add(AuthLoadAccountsRequested());
  }

  final AuthRepository _authRepository;

  Future<void> _onAuthLoadAccountsRequested(
    AuthLoadAccountsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final accounts = await _authRepository.getSavedAccounts();
    emit(state.copyWith(availableAccounts: accounts));
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(user: const StatusLoading()));
    try {
      final user = await _authRepository.login(
        serverUrl: event.server,
        username: event.username,
        password: event.password,
        rememberCredentials: event.rememberCredentials,
      );
      emit(
        state.copyWith(
          user: StatusSuccess(user),
          credentials: () => _authRepository.currentCredentials,
        ),
      );
      add(AuthLoadAccountsRequested());
    } on Exception catch (error) {
      LoggerService.auth.severe('Login failed in AuthBloc', error);
      emit(state.copyWith(user: StatusError(error.toString())));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    // Keep accounts list, clear user session and reset offline mode
    emit(
      state.copyWith(
        user: const StatusInitial(),
        isDemoMode: false,
        credentials: () => null,
      ),
    );
  }

  Future<void> _onAuthDemoModeRequested(
    AuthDemoModeRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    const demoUser = User(
      id: 'demo_user',
      name: 'Demo Pilot',
      accessToken: 'demo_token',
    );
    _authRepository.setDemoUser(demoUser);
    emit(state.copyWith(isDemoMode: true, user: const StatusSuccess(demoUser)));
  }

  Future<void> _onAuthRemoveAccountRequested(
    AuthRemoveAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.removeAccount(event.id);
    add(AuthLoadAccountsRequested());
  }

  Future<void> _onAuthSwitchAccountRequested(
    AuthSwitchAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(user: const StatusLoading()));

    try {
      final User user;
      if (event.credentials.accessToken != null) {
        user = await _authRepository.loginWithToken(
          serverUrl: event.credentials.serverName,
          username: event.credentials.username,
          token: event.credentials.accessToken!,
        );
      } else {
        user = await _authRepository.login(
          serverUrl: event.credentials.serverName,
          username: event.credentials.username,
          password: event.credentials.password ?? '',
          rememberCredentials: true,
        );
      }

      emit(
        state.copyWith(
          user: StatusSuccess(user),
          credentials: () => _authRepository.currentCredentials,
        ),
      );
      add(AuthLoadAccountsRequested());
    } on Exception catch (error) {
      LoggerService.auth.warning('Account switch failed', error);
      emit(state.copyWith(user: StatusError(error.toString())));
    }
  }
}
