import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

class JellyfinUrlService implements MediaUrlService {
  JellyfinUrlService(this._jellyfinClientService);
  final JellyfinClientService _jellyfinClientService;

  String get _baseUrl {
    final credentials = _jellyfinClientService.credentials;
    if (credentials == null) throw Exception('No active session');
    return _cleanBaseUrl(credentials.serverName);
  }

  String _cleanBaseUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  @override
  String getImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) {
    if (!_jellyfinClientService.hasSession) return '';
    var url = '$_baseUrl/Items/$itemId/Images/Primary?tag=0';
    if (maxWidth != null) url += '&maxWidth=$maxWidth';
    if (maxHeight != null) url += '&maxHeight=$maxHeight';
    if (quality != null) url += '&quality=$quality';
    return url;
  }

  @override
  String getBackdropUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) {
    if (!_jellyfinClientService.hasSession) return '';
    var url = '$_baseUrl/Items/$itemId/Images/Backdrop/0?tag=0';
    if (maxWidth != null) url += '&maxWidth=$maxWidth';
    if (maxHeight != null) url += '&maxHeight=$maxHeight';
    if (quality != null) url += '&quality=$quality';
    return url;
  }

  @override
  String getStreamUrl(String itemId) {
    if (!_jellyfinClientService.hasSession) return '';
    return '$_baseUrl/Items/$itemId/Download?api_key=${_jellyfinClientService.accessToken}';
  }

  @override
  String getDownloadUrl(String itemId, {int? maxHeight}) {
    if (!_jellyfinClientService.hasSession) return '';
    final token = _jellyfinClientService.accessToken;

    if (maxHeight == null) {
      return '$_baseUrl/Items/$itemId/Download?api_key=$token';
    }

    return '$_baseUrl/Videos/$itemId/stream.mp4'
        '?container=mp4'
        '&videoCodec=h264'
        '&audioCodec=aac'
        '&maxHeight=$maxHeight'
        '&api_key=$token';
  }

  @override
  String generateTranscodeUrl({
    required String itemId,
    required String mediaSourceId,
  }) {
    if (!_jellyfinClientService.hasSession) return '';
    final token = _jellyfinClientService.accessToken;

    return '$_baseUrl/Videos/$itemId/master.m3u8'
        '?mediaSourceId=$mediaSourceId'
        '&videoCodec=h264'
        '&audioCodec=aac,mp3'
        '&allowVideoStreamCopy=true'
        '&allowAudioStreamCopy=true'
        '&transcodingContainer=ts'
        '&segmentContainer=ts'
        '&minSegments=1'
        '&breakOnNonKeyFrames=True'
        '&api_key=$token';
  }
}
