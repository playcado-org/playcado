import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/player/bloc/player_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    LoggerService.bloc.info(
      '[Bloc: ${bloc.runtimeType}] [Event: ${event.runtimeType}]',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    LoggerService.bloc.severe(
      '[Bloc: ${bloc.runtimeType}] [Error] $error',
      error,
      stackTrace,
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    // Skip logging for PlayerBloc position-only updates to reduce noise
    if (bloc is PlayerBloc &&
        change.currentState is PlayerState &&
        change.nextState is PlayerState) {
      if ((change.currentState as PlayerState).isPositionOnlyChange(
        change.nextState as PlayerState,
      )) {
        return;
      }
    }

    // Skip logging auth state changes to avoid leaking credentials
    if (bloc is AuthBloc) {
      LoggerService.bloc.fine('[Bloc: AuthBloc] [Transition] (state redacted)');
      return;
    }

    LoggerService.bloc.fine(
      '[Bloc: ${bloc.runtimeType}] [Transition] [From: ${change.currentState.runtimeType}] [To: ${change.nextState.runtimeType}]',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    // Usually redundant if onChange is logged, but good for
    // tracking Event->State flow. Keeping it concise as mostly
    // duplication of onChange+onEvent.
  }
}
