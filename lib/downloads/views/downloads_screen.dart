import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/active_download.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
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

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppBar(
        title: IconTitle(title: context.l10n.downloads),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          const ManagerTab(),
          const DownloadsGrid(filterType: MediaItemType.movie),
          const DownloadedTvList(),
        ],
      ),
    );
  }
}
