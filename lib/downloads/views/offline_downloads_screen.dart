import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/downloads/views/downloads_screen.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/widgets/widgets.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen>
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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
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
          const DownloadedTvGrid(),
        ],
      ),
    );
  }
}
