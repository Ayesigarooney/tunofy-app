import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String _widgetName = 'NowPlayingWidget';

  static String? _lastStationName;
  static bool _lastIsPlaying = false;

  static Future<void> updateNowPlaying({
    required String stationName,
    required String stationCategory,
    String? stationLogoUrl,
    required bool isPlaying,
  }) async {
    if (stationName == _lastStationName && isPlaying == _lastIsPlaying) return;

    _lastStationName = stationName;
    _lastIsPlaying = isPlaying;

    try {
      await HomeWidget.saveWidgetData('station_name', stationName);
      await HomeWidget.saveWidgetData('station_category', stationCategory);
      await HomeWidget.saveWidgetData(
        'station_logo_url',
        stationLogoUrl ?? '',
      );
      await HomeWidget.saveWidgetData('is_playing', isPlaying);
      await HomeWidget.updateWidget(name: _widgetName);
    } catch (_) {}
  }

  static Future<void> clearWidget() async {
    if (_lastStationName == null && !_lastIsPlaying) return;

    _lastStationName = null;
    _lastIsPlaying = false;

    try {
      await HomeWidget.saveWidgetData('station_name', 'Tunofy');
      await HomeWidget.saveWidgetData('station_category', '');
      await HomeWidget.saveWidgetData('station_logo_url', '');
      await HomeWidget.saveWidgetData('is_playing', false);
      await HomeWidget.updateWidget(name: _widgetName);
    } catch (_) {}
  }
}
