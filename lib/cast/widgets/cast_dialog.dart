import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/cast/cast_device_manager.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class CastDeviceListDialog extends StatelessWidget {
  const CastDeviceListDialog({
    super.key,
    this.onDeviceSelected,
    this.autoPlayItem,
  });
  final void Function(GoogleCastDevice)? onDeviceSelected;
  final MediaItem? autoPlayItem;

  @override
  Widget build(BuildContext context) {
    final castDeviceManager = context.read<CastDeviceManager>();
    final playerBloc = context.read<PlayerBloc>();

    return StreamBuilder<GoogleCastSession?>(
      stream: castDeviceManager.currentSessionStream,
      initialData: castDeviceManager.currentSession,
      builder: (context, sessionSnapshot) {
        final currentSession = sessionSnapshot.data;
        final isConnected =
            castDeviceManager.isConnected ||
            currentSession?.connectionState == GoogleCastConnectState.connected;
        final connectedDevice = currentSession?.device;

        return AlertDialog(
          title: Text(
            isConnected
                ? context.l10n.connectedTo(
                    connectedDevice?.friendlyName ?? context.l10n.unknown,
                  )
                : context.l10n.selectADevice,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<GoogleCastDevice>>(
              stream: castDeviceManager.devicesStream,
              initialData: const [],
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(context.l10n.searchingForDevices),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isCurrentDevice =
                        isConnected &&
                        device.deviceID == connectedDevice?.deviceID;

                    return ListTile(
                      leading: PlaycadoIcon(
                        PlaycadoIcons.smartTv,
                        color: isCurrentDevice ? Colors.blue : null,
                      ),
                      title: Text(
                        device.friendlyName,
                        style: TextStyle(
                          fontWeight: isCurrentDevice ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(device.modelName ?? ''),
                      trailing: isCurrentDevice
                          ? const PlaycadoIcon(
                              PlaycadoIcons.check,
                              color: Colors.blue,
                            )
                          : null,
                      onTap: () {
                        if (onDeviceSelected != null) {
                          onDeviceSelected!(device);
                        } else {
                          context.pop();

                          if (autoPlayItem != null) {
                            playerBloc.add(
                              PlayerCastRequested(item: autoPlayItem!),
                            );
                          }

                          unawaited(castDeviceManager.connect(device));

                          SnackbarHelper.showInfo(
                            context,
                            context.l10n.connectingTo(device.friendlyName),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            if (isConnected)
              TextButton(
                onPressed: () {
                  context.pop();
                  unawaited(castDeviceManager.disconnect());
                },
                child: Text(
                  context.l10n.stopCasting,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}
