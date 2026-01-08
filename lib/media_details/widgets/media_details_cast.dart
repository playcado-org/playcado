import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

class MediaDetailsCast extends StatelessWidget {
  const MediaDetailsCast({required this.people, super.key});
  final List<MediaPerson> people;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urlGenerator = context.read<MediaUrlService>();

    final scale = MediaQuery.textScalerOf(context).scale(1);
    final avatarRadius = 35.0 * scale;
    final itemWidth = 90.0 * scale;
    final listHeight = 150.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            context.l10n.cast,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              final imageUrl = urlGenerator.getImageUrl(person.id);

              return Container(
                width: itemWidth,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      person.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (person.role case final role? when role.isNotEmpty)
                      Text(
                        role,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
