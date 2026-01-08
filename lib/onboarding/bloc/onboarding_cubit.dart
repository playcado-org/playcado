import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/services/preferences_service.dart';

class OnboardingCubit extends Cubit<bool> {
  // We inject the initial value so the app knows the state
  // synchronously at startup
  OnboardingCubit({
    required PreferencesService preferencesService,
    required bool isFirstRun,
  }) : _preferencesService = preferencesService,
       super(isFirstRun);
  final PreferencesService _preferencesService;

  Future<void> completeOnboarding() async {
    await _preferencesService.setFirstRunCompleted();
    emit(false); // Emits state change, Router picks this up immediately
  }
}
