import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/cast/cast.dart';
import 'package:playcado/devtools/bloc/dev_tools_bloc.dart';
import 'package:playcado/downloads_repository/downloads_repository.dart';
import 'package:playcado/player/engine/cast_player_engine.dart';
import 'package:playcado/services/preferences_service.dart';
import 'package:playcado/services/secure_storage_service.dart';
import 'package:playcado/widgets/snackbar_helper.dart';

class DevToolsScreen extends StatelessWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DevToolsBloc(
        preferencesService: context.read<PreferencesService>(),
        castDeviceManager: context.read<CastDeviceManager>(),
        castPlayerEngine: context.read<CastPlayerEngine>(),
        downloadsRepository: context.read<DownloadsRepository>(),
        secureStorage: context.read<SecureStorageService>(),
      )..add(DevToolsInitialized()),
      child: const _DevToolsView(),
    );
  }
}

class _DevToolsView extends StatelessWidget {
  const _DevToolsView();

  void _showCastDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const CastDeviceListDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Tools')),
      body: BlocListener<DevToolsBloc, DevToolsState>(
        listener: (context, state) {
          if (state.message case final message? when message.isNotEmpty) {
            if (state.status == DevToolsStatus.error) {
              SnackbarHelper.showError(context, message);
            } else if (state.status == DevToolsStatus.success) {
              SnackbarHelper.showSuccess(context, message);
            } else {
              SnackbarHelper.showInfo(context, state.message!);
            }
          }
        },
        child: BlocBuilder<DevToolsBloc, DevToolsState>(
          builder: (context, state) {
            final isConnected = state.isCastConnected;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DevToolButton(
                  title: 'Enable Demo Mode',
                  color: Colors.blue,
                  onTap: () {
                    context.read<AuthBloc>().add(AuthDemoModeRequested());
                    context.go('/');
                  },
                ),
                const SizedBox(height: 16),
                _DevToolButton(
                  title: isConnected
                      ? 'Play "Big Buck Bunny" (Ready)'
                      : 'Cast "Big Buck Bunny" Test',
                  color: isConnected ? Colors.green : null,
                  onTap: () {
                    if (isConnected) {
                      context.read<DevToolsBloc>().add(
                        DevToolsCastTestVideoRequested(),
                      );
                    } else {
                      _showCastDialog(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isConnected) ...[
                  _DevToolButton(
                    title: 'Disconnect Session',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => context.read<DevToolsBloc>().add(
                      DevToolsDisconnectCastRequested(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _DevToolButton(
                  title: 'Clear Secure Storage',
                  color: Colors.red,
                  onTap: () => context.read<DevToolsBloc>().add(
                    DevToolsClearSecureStorageRequested(),
                  ),
                ),
                const SizedBox(height: 16),
                _DevToolButton(
                  title: 'Clear App Preferences',
                  color: Colors.red,
                  onTap: () => context.read<DevToolsBloc>().add(
                    DevToolsClearPreferencesServiceRequested(),
                  ),
                ),
                const SizedBox(height: 16),
                _DevToolButton(
                  title: 'Clear Downloads Metadata',
                  color: Colors.red,
                  onTap: () => context.read<DevToolsBloc>().add(
                    DevToolsClearDownloadsDataRequested(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DevToolButton extends StatelessWidget {
  const _DevToolButton({required this.title, required this.onTap, this.color});
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        color ?? Theme.of(context).colorScheme.secondaryContainer;
    final foregroundColor = color != null
        ? Colors.white
        : Theme.of(context).colorScheme.onSecondaryContainer;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onTap,
      label: Text(title),
    );
  }
}
