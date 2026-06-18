import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    LoggerService.bloc.info('EVENT  [${bloc.runtimeType}] $event');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    LoggerService.bloc.severe(
      'ERROR  [${bloc.runtimeType}] $error',
      error,
      stackTrace,
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    // Skip logging for VideoPlayerBloc position-only updates to reduce noise
    if (bloc is VideoPlayerBloc &&
        change.currentState is VideoPlayerState &&
        change.nextState is VideoPlayerState) {
      if ((change.currentState as VideoPlayerState).isPositionOnlyChange(
        change.nextState as VideoPlayerState,
      )) {
        return;
      }
    }

    // Skip logging auth state changes to avoid leaking credentials
    if (bloc is AuthBloc) {
      LoggerService.bloc.fine('CHANGE [AuthBloc] (state redacted)');
      return;
    }

    // Multi-line logging for easier diffing
    LoggerService.bloc.fine(
      'CHANGE [${bloc.runtimeType}]\n'
      '   Curr: ${change.currentState}\n'
      '   Next: ${change.nextState}',
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
