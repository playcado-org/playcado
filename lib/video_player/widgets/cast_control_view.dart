import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/cast/cast.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/widgets/widgets.dart';

class CastControlView extends StatelessWidget {
  const CastControlView({required this.item, super.key});
  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlaycadoIcon(
            PlaycadoIcons.cast,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            context.l10n.castingToDevice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              item?.name ?? context.l10n.mediaType,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () {
              unawaited(context.read<CastService>().disconnect());
            },
            icon: const PlaycadoIcon(PlaycadoIcons.stop),
            label: Text(context.l10n.stopCasting),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
