import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/downloads/models/active_download.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/downloads/services/downloads_manager_service.dart';
import 'package:playcado/media/models/media_item.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc({required DownloadsManagerService downloadsManagerService})
    : _downloadsManagerService = downloadsManagerService,
      super(const DownloadsState()) {
    unawaited(downloadsManagerService.ensureInitialized());

    on<DownloadsRequested>((event, emit) async {
      await _downloadsManagerService.addMediaDownload(event.item);
    });
    on<DownloadsDeleteRequested>((event, emit) async {
      await _downloadsManagerService.deleteDownload(event.id);
    });
    on<DownloadsPauseRequested>((event, emit) async {
      await _downloadsManagerService.pauseDownload(event.id);
    });
    on<DownloadsResumeRequested>((event, emit) async {
      await _downloadsManagerService.resumeDownload(event.id);
    });
    on<_ActiveUpdated>((event, emit) {
      _activeLoaded = true;
      final offlineIds = state.offlineLibrary.map((e) => e.id).toSet();
      emit(
        state.copyWith(
          activeDownloads: event.items
              .where((e) => !offlineIds.contains(e.id))
              .toList(),
          isLoading: !(_activeLoaded && _libraryLoaded),
        ),
      );
    });
    on<_LibraryUpdated>((event, emit) {
      _libraryLoaded = true;
      final offlineIds = event.items.map((e) => e.id).toSet();
      emit(
        state.copyWith(
          activeDownloads: state.activeDownloads
              .where((e) => !offlineIds.contains(e.id))
              .toList(),
          offlineLibrary: event.items,
          isLoading: !(_activeLoaded && _libraryLoaded),
        ),
      );
    });

    _initListeners();
  }

  final DownloadsManagerService _downloadsManagerService;
  bool _activeLoaded = false;
  bool _libraryLoaded = false;
  StreamSubscription<List<ActiveDownload>>? _activeSub;
  StreamSubscription<List<DownloadedMediaItem>>? _libSub;

  void _initListeners() {
    _activeSub = _downloadsManagerService.activeDownloadsStream.listen((items) {
      add(_ActiveUpdated(items));
    });
    _libSub = _downloadsManagerService.offlineLibraryStream.listen((items) {
      add(_LibraryUpdated(items));
    });
  }

  @override
  Future<void> close() {
    _activeSub?.cancel();
    _libSub?.cancel();
    return super.close();
  }
}
