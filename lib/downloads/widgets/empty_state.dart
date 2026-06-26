part of '../views/downloads_screen.dart';

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
    this.showBrowseButton = true,
  });
  final PlaycadoIcons icon;
  final String message;
  final String subMessage;
  final bool showBrowseButton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: PlaycadoIcon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (showBrowseButton) ...[
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: () => context.go(AppRouter.basePath),
              icon: const PlaycadoIcon(PlaycadoIcons.home),
              label: Text(context.l10n.browseLibrary),
            ),
          ],
        ],
      ),
    );
  }
}
