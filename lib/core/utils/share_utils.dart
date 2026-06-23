import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  static void shareRadioStation(String name, String url) {
    final text = 'Tune in to $name on Tunofy!\n\n'
        'Listen live: $url\n\n'
        'Download Tunofy: https://play.google.com/store/apps/details?id=com.rooney.tunofy';
    Share.share(text);
  }

  static void shareMovie(String title, String? overview, String? url) {
    final text = 'Check out "$title" on Tunofy!\n\n'
        '${overview ?? ""}\n\n'
        '${url ?? "Download Tunofy: https://play.google.com/store/apps/details?id=com.rooney.tunofy"}';
    Share.share(text);
  }

  static void shareNewsArticle(String title, String? url, String? source) {
    final text = '$title\n\n'
        '${url ?? ""}\n'
        '${source != null ? "Via $source" : ""}\n\n'
        'Shared from Tunofy — https://play.google.com/store/apps/details?id=com.rooney.tunofy';
    Share.share(text);
  }

  static void shareNowPlaying(String stationName, String? trackInfo) {
    final text = 'Now playing on Tunofy: $stationName'
        '${trackInfo != null ? " — $trackInfo" : ""}\n\n'
        'Download: https://play.google.com/store/apps/details?id=com.rooney.tunofy\n'
        '#Tunofy #NowPlaying';
    Share.share(text);
  }

  static Future<void> shareRecording(String filePath, String stationName) async {
    final file = XFile(filePath, mimeType: 'audio/mp4');
    await Share.shareXFiles([file], text: 'Recorded from $stationName on Tunofy\n\nDownload: https://play.google.com/store/apps/details?id=com.rooney.tunofy');
  }
}
