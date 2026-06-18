import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/downloads/services/downloads_manager_service.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/logger_service.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc({required DownloadsManagerService downloadsManagerService})
    : _downloadsManagerService = downloadsManagerService,
      super(const DownloadsState()) {
    on<DownloadsDeleteRequested>(_onDownloadsDeleteRequested);
    on<DownloadsInitialized>(_onDownloadsInitialized);
    on<DownloadsPauseRequested>(_onDownloadsPauseRequested);
    on<DownloadsResumeRequested>(_onDownloadsResumeRequested);
    on<DownloadsStartRequested>(_onDownloadsStartRequested);
    on<DownloadsRequested>(_onDownloadsRequested);
    on<DownloadsUpdated>(_onDownloadsUpdated);

    add(DownloadsInitialized());
  }
  final DownloadsManagerService _downloadsManagerService;
  StreamSubscription<List<DownloadItem>>? _subscription;

  Future<void> _onDownloadsDeleteRequested(
    DownloadsDeleteRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadsManagerService.deleteDownload(event.id);
  }

  void _onDownloadsInitialized(
    DownloadsInitialized event,
    Emitter<DownloadsState> emit,
  ) {
    LoggerService.downloads.info('Initializing DownloadsBloc');
    if (_downloadsManagerService.currentDownloads.isNotEmpty) {
      emit(
        state.copyWith(
          downloads: _downloadsManagerService.currentDownloads,
          isLoading: false,
        ),
      );
    }

    unawaited(_subscription?.cancel());
    _subscription = _downloadsManagerService.downloads.listen((items) {
      add(DownloadsUpdated(items));
    });
  }

  Future<void> _onDownloadsPauseRequested(
    DownloadsPauseRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadsManagerService.pauseDownload(event.id);
  }

  Future<void> _onDownloadsResumeRequested(
    DownloadsResumeRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadsManagerService.resumeDownload(event.id);
  }

  Future<void> _onDownloadsStartRequested(
    DownloadsStartRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    LoggerService.downloads.info('User requested download: ${event.item.name}');
    try {
      await _downloadsManagerService.addDownload(event.item);
    } on Exception catch (e, s) {
      LoggerService.downloads.severe('Error adding download in Bloc', e, s);
    }
  }

  Future<void> _onDownloadsRequested(
    DownloadsRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    final item = event.item;
    LoggerService.downloads.info(
      'Preparing original quality download for ${item.name}',
    );

    try {
      await _downloadsManagerService.addMediaDownload(item);
    } on Exception catch (e, s) {
      LoggerService.downloads.severe('Error preparing download', e, s);
    }
  }

  void _onDownloadsUpdated(
    DownloadsUpdated event,
    Emitter<DownloadsState> emit,
  ) {
    emit(state.copyWith(downloads: event.items, isLoading: false));
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
