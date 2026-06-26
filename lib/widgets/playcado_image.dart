import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:playcado/widgets/widgets.dart';

class PlaycadoImage extends StatelessWidget {
  const PlaycadoImage({
    required this.imageUrl,
    super.key,
    this.localFile,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.filterQuality = FilterQuality.low,
  });

  final String imageUrl;
  final String? localFile;
  final BoxFit fit;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    if (localFile != null) {
      final file = File(localFile!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          filterQuality: filterQuality,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(context, error),
        );
      }
    }

    if (imageUrl.isEmpty) {
      return _buildFallback(context, 'No local file and image URL is empty');
    }

    return PlaycadoNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
    );
  }

  Widget _buildFallback(BuildContext context, Object error) {
    if (errorWidget != null) {
      return errorWidget!(context, imageUrl, error);
    }
    final theme = Theme.of(context);
    return Center(
      child: PlaycadoIcon(
        PlaycadoIcons.imageNotFound,
        color: theme.colorScheme.error,
      ),
    );
  }
}
