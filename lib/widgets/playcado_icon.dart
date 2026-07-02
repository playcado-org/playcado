import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A standardized icon widget for the Playcado app.
/// Wraps [HugeIcon] to provide a consistent look and feel
/// using [PlaycadoIcons].
class PlaycadoIcon extends StatelessWidget {
  const PlaycadoIcon(
    this.icon, {
    super.key,
    this.strokeWidth = 2,
    this.color,
    this.size,
  });

  final Color? color;
  final PlaycadoIcons icon;
  final double strokeWidth;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      color: color,
      icon: icon.icon,
      strokeWidth: strokeWidth,
      size: size ?? 24,
    );
  }
}

enum PlaycadoIcons {
  alert(HugeIcons.strokeRoundedAlert02),
  arrowDown(HugeIcons.strokeRoundedArrowDown01),
  arrowRight(HugeIcons.strokeRoundedArrowRight01),
  calendar(HugeIcons.strokeRoundedCalendar03),
  cancel(HugeIcons.strokeRoundedCancel01),
  cast(HugeIcons.strokeRoundedMirroringScreen),
  check(HugeIcons.strokeRoundedTick01),
  clock(HugeIcons.strokeRoundedClock01),
  close(HugeIcons.strokeRoundedCancel01),
  developer(HugeIcons.strokeRoundedSourceCode),
  download(HugeIcons.strokeRoundedDownload01),
  error(HugeIcons.strokeRoundedAlertCircle),
  feedback(HugeIcons.strokeRoundedMessageEdit01),
  folder(HugeIcons.strokeRoundedFolder01),
  forward10(HugeIcons.strokeRoundedGoForward10Sec),
  fullscreen(HugeIcons.strokeRoundedArrowExpand),
  fullscreenExit(HugeIcons.strokeRoundedArrowShrink),
  graphicEq(HugeIcons.strokeRoundedMusicNote01),
  home(HugeIcons.strokeRoundedHome03),
  image(HugeIcons.strokeRoundedImage02),
  imageNotFound(HugeIcons.strokeRoundedImage01),
  info(HugeIcons.strokeRoundedInformationCircle),
  lock(HugeIcons.strokeRoundedLockPassword),
  logout(HugeIcons.strokeRoundedLogout01),
  menu(HugeIcons.strokeRoundedMenu01),
  more(HugeIcons.strokeRoundedMoreVertical),
  movie(HugeIcons.strokeRoundedFlimSlate),
  music(HugeIcons.strokeRoundedMusicNote01),
  pause(HugeIcons.strokeRoundedPause),
  pauseCircle(HugeIcons.strokeRoundedPauseCircle),
  person(HugeIcons.strokeRoundedUser),
  placeholderImage(HugeIcons.strokeRoundedImage01),
  play(HugeIcons.strokeRoundedPlay),
  refresh(HugeIcons.strokeRoundedRefresh),
  replay10(HugeIcons.strokeRoundedGoBackward10Sec),
  search(HugeIcons.strokeRoundedSearch01),
  skipNext(HugeIcons.strokeRoundedArrowRight01),
  smartTv(HugeIcons.strokeRoundedTvSmart),
  sort(HugeIcons.strokeRoundedSortByDown02),
  stop(HugeIcons.strokeRoundedStop),
  subtitles(HugeIcons.strokeRoundedSubtitle),
  trash(HugeIcons.strokeRoundedDelete02),
  tv(HugeIcons.strokeRoundedTv01),
  view(HugeIcons.strokeRoundedView),
  viewOff(HugeIcons.strokeRoundedViewOff),
  wifiOff(HugeIcons.strokeRoundedWifiDisconnected01);

  const PlaycadoIcons(this.icon);

  final List<List<dynamic>> icon;
}
