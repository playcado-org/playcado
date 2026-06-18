import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class OfflineMediaDetailPage extends StatelessWidget {
  static Route<void> route(DownloadItem item) {
    return MaterialPageRoute(
      builder: (context) => OfflineMediaDetailPage(item: item),
    );
  }

  const OfflineMediaDetailPage({required this.item, super.key});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            child: BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _OfflineHeader(item: item)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.type case final type?)
                        _Badge(
                          label: type.label,
                          color: colorScheme.primaryContainer,
                          textColor: colorScheme.onPrimaryContainer,
                        ),
                      if (item.productionYear case final year?) ...[
                        const SizedBox(width: 8),
                        _Badge(
                          label: year,
                          color: colorScheme.tertiaryContainer,
                          textColor: colorScheme.onTertiaryContainer,
                        ),
                      ],
                      if (item.totalBytes > 0) ...[
                        const SizedBox(width: 8),
                        _Badge(
                          label: Formatters.formatBytes(item.totalBytes),
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ],
                  ),
                  if (item.overview case final overview?
                      when overview.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.overview,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () {
                        final mediaItem = MediaItem(
                          id: item.id,
                          name: item.name,
                          overview: item.overview,
                          type: item.type ?? MediaItemType.movie,
                        );
                        context.read<PlayerBloc>().add(
                          PlayerPlayRequested(
                            item: mediaItem,
                            localPath: item.localPath,
                          ),
                        );
                      },
                      icon: const PlaycadoIcon(PlaycadoIcons.play, size: 28),
                      label: Text(
                        context.l10n.playOffline,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<DownloadsBloc>().add(
                          DownloadsDeleteRequested(item.id),
                        );
                        SnackbarHelper.showInfo(
                          context,
                          context.l10n.deletedItem(item.name),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const PlaycadoIcon(PlaycadoIcons.trash),
                      label: Text(context.l10n.delete),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineHeader extends StatelessWidget {
  const _OfflineHeader({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final height = MediaQuery.of(context).size.width * (9 / 16);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl != null)
            PlaycadoNetworkImage(
              imageUrl: item.imageUrl!,
              placeholder: (context, url) =>
                  ColoredBox(color: colorScheme.surfaceContainerHighest),
              errorWidget: (context, url, error) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: PlaycadoIcon(
                    PlaycadoIcons.imageNotFound,
                    color: colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: PlaycadoIcon(
                  PlaycadoIcons.movie,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 64,
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black54,
                  Colors.black,
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
