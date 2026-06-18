import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/downloads/views/offline_media_detail_page.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

part 'downloaded_tv_list.dart';
part 'downloads_grid.dart';
part 'manager_tab.dart';
part 'offline_body.dart';
part '../widgets/active_download_card.dart';
part '../widgets/completed_download_card.dart';
part '../widgets/download_poster.dart';
part '../widgets/empty_state.dart';
part '../widgets/episode_tile.dart';
part '../widgets/section_header.dart';
part '../widgets/series_header.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isOfflineMode = context.select<AuthBloc, bool>(
      (b) => b.state.isOfflineMode,
    );

    if (isOfflineMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.offlineDownloads),
          centerTitle: false,
        ),
        body: const _OfflineBody(),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: IconTitle(title: context.l10n.downloads),
          centerTitle: false,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            tabs: [
              Tab(text: context.l10n.manager),
              Tab(text: context.l10n.movies),
              Tab(text: context.l10n.tvShows),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManagerTab(),
            _DownloadsGrid(filterType: MediaItemType.movie),
            _DownloadedTvList(),
          ],
        ),
      ),
    );
  }
}
