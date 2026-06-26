import 'dart:convert';
import '../models/radio_station.dart';
import '../services/channel_service.dart';
import '../services/radio_browser_service.dart';
import 'settings_repository.dart';

enum DataSource { live, cached, fallback }

class StationsResult<T> {
  final List<T> data;
  final DataSource source;
  StationsResult(this.data, this.source);
}

class StationsRepository {
  final ChannelService _channelService;
  final RadioBrowserService _radioBrowserService;
  final SettingsRepository _settings;

  List<RadioStation>? _radioCache;
  List<TvChannel>? _tvCache;
  List<String>? _radioCategories;
  List<String>? _tvCategories;

  // Separate offline flags per content type
  bool isRadioOffline = false;
  bool isTvOffline = false;

  bool get isOffline => isRadioOffline && isTvOffline;

  StationsRepository({required SettingsRepository settingsRepository})
      : _settings = settingsRepository,
        _channelService = ChannelService(),
        _radioBrowserService = RadioBrowserService();

  Future<StationsResult<RadioStation>> getRadioStations() async {
    if (_radioCache != null) {
      return StationsResult(_radioCache!, DataSource.live);
    }
    try {
      final stations = await _radioBrowserService.getStations();
      if (stations.isNotEmpty) {
        _radioCache = _buildRadioList(stations);
        _computeRadioCategories();
        isRadioOffline = false;
        _cacheRadioStations();
        return StationsResult(_radioCache!, DataSource.live);
      }
    } catch (e) {
      final cached = _loadCachedRadioStations();
      if (cached != null) {
        _radioCache = _buildRadioList(cached);
        _computeRadioCategories();
        isRadioOffline = true;
        return StationsResult(_radioCache!, DataSource.cached);
      }
    }
    _radioCache = getFallbackRadioStations();
    _radioCategories = null;
    isRadioOffline = true;
    return StationsResult(_radioCache!, DataSource.fallback);
  }

  Future<StationsResult<TvChannel>> getTvChannels() async {
    if (_tvCache != null) {
      return StationsResult(_tvCache!, DataSource.live);
    }
    try {
      final channels = await _channelService.getChannels();
      if (channels.isNotEmpty) {
        _tvCache = _buildTvList(channels);
        _computeTvCategories();
        isTvOffline = false;
        _cacheTvChannels();
        return StationsResult(_tvCache!, DataSource.live);
      }
    } catch (e) {
      final cached = _loadCachedTvChannels();
      if (cached != null) {
        _tvCache = _buildTvList(cached);
        _computeTvCategories();
        isTvOffline = true;
        return StationsResult(_tvCache!, DataSource.cached);
      }
    }
    _tvCache = getFallbackTvChannels();
    _tvCategories = null;
    isTvOffline = true;
    return StationsResult(_tvCache!, DataSource.fallback);
  }


  void _cacheRadioStations() {
    if (_radioCache == null) return;
    try {
      final json = jsonEncode(_radioCache!.map((s) => s.toJson()).toList());
      _settings.setCachedRadioStationsJson(json);
    } catch (e) {
      // Non-critical: cache write failure is acceptable
    }
  }

  List<RadioStation>? _loadCachedRadioStations() {
    try {
      final json = _settings.getCachedRadioStationsJson();
      if (json == null) return null;
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  void _cacheTvChannels() {
    if (_tvCache == null) return;
    try {
      final json = jsonEncode(_tvCache!.map((c) => c.toJson()).toList());
      _settings.setCachedTvChannelsJson(json);
    } catch (e) {
      // Non-critical
    }
  }

  List<TvChannel>? _loadCachedTvChannels() {
    try {
      final json = _settings.getCachedTvChannelsJson();
      if (json == null) return null;
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => TvChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  List<String> getRadioCategories() =>
      _radioCategories ?? _fallbackRadioCategories;

  List<String> getTvCategories() =>
      _tvCategories ?? _fallbackTvCategories;

  void _computeRadioCategories() {
    if (_radioCache == null) return;
    final cats = <String>{};
    for (final s in _radioCache!) {
      if (!s.isCustomStation && s.category.isNotEmpty) cats.add(s.category);
    }
    _radioCategories = ['All', ...cats.toList()..sort()];
  }

  void _computeTvCategories() {
    if (_tvCache == null) return;
    final cats = <String>{};
    for (final c in _tvCache!) {
      if (!c.isCustomChannel && c.category.isNotEmpty) cats.add(c.category);
    }
    _tvCategories = ['All', ...cats.toList()..sort()];
  }

  List<RadioStation> _buildRadioList(List<RadioStation> fetched) =>
      [..._ugandanStations, ...fetched];

  List<TvChannel> _buildTvList(List<TvChannel> fetched) {
    final sorted = List<TvChannel>.from(fetched)
      ..sort((a, b) {
        if (a.country == 'UG' && b.country != 'UG') return -1;
        if (a.country != 'UG' && b.country == 'UG') return 1;
        return 0;
      });
    return [..._ugandanTvChannels, ...sorted];
  }


  // ─── Curated Ugandan radio stations ─────────────────────────────────────────

  static final _ugandanStations = <RadioStation>[
    // ── Bunyoro Region ──
    RadioStation(id: 'ug_radiohoima88', name: 'Radio Hoima 88.6', primaryUrl: 'https://r1.comcities.com/proxy/ytswyfvh/stream', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 128, description: 'Bunyoro\'s leading station since 1999'),
    RadioStation(id: 'ug_liberty89', name: 'Liberty Radio 89.0', primaryUrl: 'https://libertyfmhoima.com/wpstream/liberty-radio-2/', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Ekyererezí Kya Bunyoro — voice of Bunyoro'),
    RadioStation(id: 'ug_kabalegafm', name: 'Kabalega FM', primaryUrl: 'https://stream.hydeinnovations.com:8028/stream', category: 'World & Culture', country: 'UG', language: 'lg', bitrate: 128, description: 'Bunyoro kingdom heritage and music'),
    RadioStation(id: 'ug_spicefm89', name: 'Spice FM 89.9', primaryUrl: 'https://dc4.serverse.com/proxy/spicefm/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 96, description: 'Hoima Oil City\'s vibrant station'),
    RadioStation(id: 'ug_kicorhythm', name: 'KICO Rhythm Radio', primaryUrl: 'https://radio.julyhost.net/8168/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Bunyoro music and variety'),
    RadioStation(id: 'ug_kazinjema', name: 'Kazi Njema Radio', primaryUrl: 'https://cast3.asurahosting.com/proxy/habincon/stream?ver=573654', category: 'Public & Community', country: 'UG', language: 'sw', bitrate: 128, description: 'Community radio for Bunyoro'),
    RadioStation(id: 'ug_radiomariahoima', name: 'Radio Maria Hoima', primaryUrl: 'https://dreamsiteradiocp2.com/proxy/rmugandahoima?mp=/stream/', category: 'Religious', country: 'UG', language: 'lg', bitrate: 48, description: 'Catholic faith in Bunyoro'),
    RadioStation(id: 'ug_kkcr91', name: 'KKCR FM 91.7', primaryUrl: 'https://radio.garden/api/ara/content/listen/n2JGayju/channel.mp3', category: 'Public & Community', country: 'UG', language: 'lg', bitrate: 128, description: 'Kagadi community radio'),
    RadioStation(id: 'ug_paradigm100', name: 'Paradigm FM 100.0', primaryUrl: 'https://radio.garden/api/ara/content/listen/aZky72hl/channel.mp3', category: 'News & Talk', country: 'UG', language: 'sw', bitrate: 128, description: 'Radio Ensigazi — Kagadi community talk'),
    RadioStation(id: 'ug_kdr100', name: 'KDR 100.3 FM', primaryUrl: 'https://radio.garden/api/ara/content/listen/p17LHzeT/channel.mp3', category: 'News & Talk', country: 'UG', language: 'en', bitrate: 128, description: 'Karuguuza Development Radio — Kibaale'),
    RadioStation(id: 'ug_biisofm97', name: 'Biiso FM 97.8', primaryUrl: 'https://radio.garden/api/ara/content/listen/ECbUpQQ2/channel.mp3', category: 'Music', country: 'UG', language: 'lg', bitrate: 128, description: 'Biso community music and talk'),
    RadioStation(id: 'ug_newlife96', name: 'New Life Radio 96.2', primaryUrl: 'https://radio.garden/api/ara/content/listen/lNzOgPEv/channel.mp3', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Buhimba Christian radio'),
    RadioStation(id: 'ug_radio7100', name: 'Radio 7 FM 100.7', primaryUrl: 'https://radio.garden/api/ara/content/listen/0IcmQSfd/channel.mp3', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Masindi\'s leading music and news station'),
    RadioStation(id: 'ug_kiruhura98', name: 'Kiruhura FM 98.6', primaryUrl: 'https://c18.radioboss.fm:8597/stream', category: 'Music', country: 'UG', language: 'lg', bitrate: 128, description: 'Kiruhura district music and community'),
    // ── Tooro Region ──
    RadioStation(id: 'ug_voiceoftoro101', name: 'Voice of Toro FM 101.1', primaryUrl: 'https://orbit.citrus3.com:8026/stream', category: 'World & Culture', country: 'UG', language: 'en', bitrate: 128, description: 'Tooro kingdom music, news and culture'),
    RadioStation(id: 'ug_voicekamwenge87', name: 'Voice of Kamwenge 87.9', primaryUrl: 'https://radio.garden/api/ara/content/listen/EPuUUVOo/channel.mp3', category: 'Public & Community', country: 'UG', language: 'lg', bitrate: 128, description: 'Kamwenge community radio'),
    RadioStation(id: 'ug_mmuradio105', name: 'MMU Radio FM 105.2', primaryUrl: 'https://radio.garden/api/ara/content/listen/bDi0l7fq/channel.mp3', category: 'Public & Community', country: 'UG', language: 'en', bitrate: 128, description: 'Mountains of the Moon University campus radio'),
    RadioStation(id: 'ug_jubilee105_fortportal', name: 'Jubilee Radio 105.6 FM', primaryUrl: 'http://stream.zeno.fm/f3y3up2k07zuv', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Fort Portal\'s upbeat music and community station'),
    RadioStation(id: 'ug_kaseseguide100', name: 'Kasese Guide Radio 100.5', primaryUrl: 'https://radio.julyhost.net/8240/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Catholic radio serving Kasese'),
    RadioStation(id: 'ug_messiah97', name: 'Messiah Radio 97.5', primaryUrl: 'https://radio.julyhost.net/8246/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Kasese Christian radio'),
    RadioStation(id: 'ug_snowfm', name: 'Snow FM', primaryUrl: 'https://sp.streams.ovh:8032/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Kasese music and entertainment'),
    RadioStation(id: 'ug_lightfm102', name: 'Light FM 102.9', primaryUrl: 'https://radio.julyhost.net/8244/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Kasese Christian fellowship'),
    RadioStation(id: 'ug_radiowest', name: 'Radio West', primaryUrl: 'https://stream.hydeinnovations.com:2020/stream/radiowest/stream', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 128, description: 'Western Uganda news and talk'),
    // ── Kampala / Central ──
    RadioStation(id: 'ug_galaxy100', name: 'Galaxy FM 100.2', primaryUrl: 'https://stream.zeno.fm/ahtmyttw5mftv', logoUrl: 'https://www.galaxyfm.co.ug/wp-content/uploads/2018/01/Galaxy-FM-Logo.png', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Urban music and entertainment'),
    RadioStation(id: 'ug_xfm94', name: 'XFM 94.8 Kampala', primaryUrl: 'https://stream.hydeinnovations.com:2020/stream/xfm/stream', logoUrl: 'https://i.ibb.co/VBfTj1z/xfm.jpg', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Hits and pop music'),
    RadioStation(id: 'ug_kfm93', name: 'KFM 93.3', primaryUrl: 'https://radio.kfm.co.ug:8000/stream', logoUrl: 'https://i.ibb.co/PZXM2c1C/517718440-10162980039425138-9078622882750722647-n.jpg', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Entertainment and talk'),
    RadioStation(id: 'ug_sanyu88', name: 'Sanyu FM 88.2', primaryUrl: 'https://s44.myradiostream.com:8138/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 48, description: 'Uganda\'s oldest music station'),
    RadioStation(id: 'ug_capital91', name: 'Capital FM 91.3', primaryUrl: 'https://capitalfm.cloudrad.io/stream', logoUrl: 'https://capitalradio.co.ug/wp-content/uploads/2023/01/cropped-favicon-180x180.png', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Uganda\'s leading hit music station'),
    RadioStation(id: 'ug_beat96', name: 'Beat FM 96.3', primaryUrl: 'https://5230.cloudrad.io:8354/live', logoUrl: 'https://beatradio.co.ug/wp-content/uploads/2022/12/Beat-FM-Logo-1-1-e1672310266264.png', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Entertainment and variety'),
    RadioStation(id: 'ug_nrg106', name: 'NRG Uganda 106.5', primaryUrl: 'https://dc4.serverse.com/proxy/nrgugstream/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Youth, hip hop and pop'),
    RadioStation(id: 'ug_rockfm', name: 'Rock FM Uganda', primaryUrl: 'https://titan.shoutca.st:8341/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Music, news and entertainment'),
    RadioStation(id: 'ug_kiis100', name: 'KIIS 100.9', primaryUrl: 'https://14867.cloudrad.io:9224/live', logoUrl: 'https://i.ibb.co/xq6pTwv/302142045-131711916253380-781783264782417610-n.jpg', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Hot hits and urban music'),
    RadioStation(id: 'ug_next106', name: 'Next Radio 106.1', primaryUrl: 'https://stream-154.zeno.fm/lbca7zintcnuv', logoUrl: 'https://nextradio.co.ug/wp-content/uploads/2018/09/cropped-logo-1-180x180.gif', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Contemporary hits'),
    RadioStation(id: 'ug_crooze', name: 'Crooze FM', primaryUrl: 'https://stream-159.zeno.fm/vyxwdk08apxtv', logoUrl: 'https://croozefm.com/wp-content/uploads/2024/09/cropped-site-icon-180x180.png', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Smooth sounds and classics'),
    RadioStation(id: 'ug_ejazz', name: 'EJazz Radio', primaryUrl: 'https://eu1.reliastream.com/proxy/ejazzug?mp=/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 96, description: 'Jazz and smooth grooves'),
    RadioStation(id: 'ug_ejazzxtra', name: 'EJazz Xtra', primaryUrl: 'https://c32.radioboss.fm:18320/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Extra jazz selection'),
    RadioStation(id: 'ug_kaboozi87', name: 'Kaboozi FM 87.9', primaryUrl: 'https://162.244.80.52:8732/stream.mp3', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 64, description: 'Talk and current affairs'),
    RadioStation(id: 'ug_ugonlinemedia', name: 'UgOnlineMedia', primaryUrl: 'https://stream.zeno.fm/8t4dtkxfgkuuv', category: 'Public & Community', country: 'UG', language: 'en', bitrate: 0, description: 'Community information and variety'),
    RadioStation(id: 'ug_heavenfm', name: 'Heaven FM Radio', primaryUrl: 'https://stream.zeno.fm/eequgfw72hhvv', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Contemporary hits and worship'),
    RadioStation(id: 'ug_bbcuganda', name: 'BBC Radio Uganda', primaryUrl: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service_west_africa', category: 'News & Talk', country: 'UG', language: 'en', bitrate: 56, description: 'BBC World Service for Uganda'),
    // ── Eastern Uganda ──
    RadioStation(id: 'ug_kiira88', name: 'Kiira FM 88.6', primaryUrl: 'https://stream.zeno.fm/iydttapi8rguv', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 0, description: 'Jinja\'s leading station'),
    RadioStation(id: 'ug_busoga90', name: 'Busoga One 90.6', primaryUrl: 'https://stream.zeno.fm/xna2aad7gc9uv', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 0, description: 'Eastern Uganda news and talk'),
    RadioStation(id: 'ug_busogaroyal', name: 'Busoga Royal Radio', primaryUrl: 'https://cast5.my-control-panel.com/proxy/busogaroyalradio/stream', category: 'World & Culture', country: 'UG', language: 'lg', bitrate: 128, description: 'Busoga kingdom and community'),
    RadioStation(id: 'ug_bugwere', name: 'Bugwere FM', primaryUrl: 'https://stream-174.zeno.fm/jddn0e0z9f0uv', category: 'News & Talk', country: 'UG', language: 'lg', bitrate: 0, description: 'Lugwere community radio'),
    RadioStation(id: 'ug_kyogaveritas', name: 'Kyoga Veritas 91.5', primaryUrl: 'https://stream.zeno.fm/hyyzuphrsg0uv', category: 'Public & Community', country: 'UG', language: 'en', bitrate: 0, description: 'Soroti community radio'),
    RadioStation(id: 'ug_heathafro', name: 'Heathafro FM', primaryUrl: 'https://stream.zeno.fm/rdf0qac95p8uv', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Eastern Uganda music and talk'),
    // ── Western Uganda ──
    RadioStation(id: 'ug_buddu98', name: 'Radio Buddu 98.8', primaryUrl: 'https://dc4.serverse.com/proxy/ccmxrgub/stream', category: 'World & Culture', country: 'UG', language: 'lg', bitrate: 64, description: 'Buddu kingdom community radio'),
    RadioStation(id: 'ug_exodusmbarara', name: 'Exodus Comfort Radio', primaryUrl: 'https://stream.zeno.fm/k2zma0qewtjvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Mbarara gospel and community'),
    RadioStation(id: 'ug_christlove', name: 'Christ Love Radio', primaryUrl: 'https://stream.zeno.fm/orioba9siustv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Christian love and teaching'),
    // ── Northern Uganda ──
    RadioStation(id: 'ug_favour104', name: 'Favour FM 104.1 Gulu', primaryUrl: 'https://us5new.listen2myradio.com:2199/listen.php?port=8138&type=ice&mount=stream', logoUrl: 'https://i.ibb.co/P6b03Fx/image.webp', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Gospel and community radio'),
    RadioStation(id: 'ug_christlira', name: 'Christ Radio Lira', primaryUrl: 'https://stream.zeno.fm/zupkzgrj4dauv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Lira Christian radio'),
    // ── Religious ──
    RadioStation(id: 'ug_mcf98', name: 'MCF Radio 98.7', primaryUrl: 'https://streams.radio.co/s79fbbb432/listen', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Mutundwe Christian Fellowship'),
    RadioStation(id: 'ug_sanctuaryfm', name: 'Sanctuary FM', primaryUrl: 'https://stream.zeno.fm/vyx334hsbphvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Worship and fellowship'),
    RadioStation(id: 'ug_voiceheaven', name: 'Voice Of Heaven', primaryUrl: 'https://stream.zeno.fm/s961sfesdmntv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Christian radio ministry'),
    RadioStation(id: 'ug_gloryfm', name: 'Glory FM Maganjo', primaryUrl: 'https://stream.zeno.fm/bn7dbg8w0nhvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Christian worship and talk'),
    RadioStation(id: 'ug_chosenradio', name: 'Chosen Radio Uganda', primaryUrl: 'https://stream.zeno.fm/6uxwuag3srhvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Chosen generation gospel'),
    RadioStation(id: 'ug_churchradio', name: 'Church Radio', primaryUrl: 'https://stream.zeno.fm/k0weys53f78uv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Christian church broadcasting'),
    RadioStation(id: 'ug_prayertower', name: 'Prayer Tower Radio', primaryUrl: 'https://stream.zeno.fm/ymapb78yznhvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Prayer and worship'),
    RadioStation(id: 'ug_yofochm', name: 'Yofochm Radio Uganda', primaryUrl: 'https://c13.radioboss.fm:18053/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Christian teaching and gospel'),
    RadioStation(id: 'ug_dovefm', name: 'Dove FM', primaryUrl: 'https://ice64.securenetsystems.net/DOVEMAIN', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Christian family radio'),
    RadioStation(id: 'ug_gospelradioea', name: 'Gospel Radio East Africa', primaryUrl: 'https://c32.radioboss.fm:18451/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Gospel music and teachings'),
    RadioStation(id: 'ug_demagospel', name: 'Dema Gospel Promotions', primaryUrl: 'https://stream.zeno.fm/m96foqqk7bxuv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Gospel music promotions'),
    RadioStation(id: 'ug_radiomaria101', name: 'Radio Maria 101.8', primaryUrl: 'https://dreamsiteradiocp.com:8052/stream', category: 'Religious', country: 'UG', language: 'lg', bitrate: 48, description: 'Catholic faith and community'),
    RadioStation(id: 'ug_christfm91', name: 'Christ FM 91.6', primaryUrl: 'https://s39.myradiostream.com:15664/stream', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Christian music and teaching'),
    RadioStation(id: 'ug_centenary88', name: 'Centenary FM 88.1', primaryUrl: 'https://c24.radioboss.fm:18185/stream', category: 'Religious', country: 'UG', language: 'lg', bitrate: 128, description: 'Christian fellowship'),
    RadioStation(id: 'ug_pearl107', name: 'Pearl FM 107.9', primaryUrl: 'https://dc4.serverse.com/proxy/pearlfm/stream/1/', category: 'Religious', country: 'UG', language: 'lg', bitrate: 96, description: 'Gospel and religious programming'),
    RadioStation(id: 'ug_enjiri', name: 'Enjiri Radio', primaryUrl: 'https://stream.zeno.fm/xdb8nazajqcvv', category: 'Religious', country: 'UG', language: 'en', bitrate: 0, description: 'Christian talk and gospel'),
    RadioStation(id: 'ug_emcradio', name: 'EMC Radio', primaryUrl: 'https://c22.radioboss.fm:18040/stream', logoUrl: 'https://i.ibb.co/Fwv8RNs/emcradio.jpg', category: 'Religious', country: 'UG', language: 'en', bitrate: 128, description: 'Gospel and talk'),
    // ── Music & Culture ──
    RadioStation(id: 'ug_jembe', name: 'Jembe FM', primaryUrl: 'https://cast3.asurahosting.com/proxy/jembemed/stream', category: 'Music', country: 'UG', language: 'en', bitrate: 128, description: 'Current affairs and music'),
    RadioStation(id: 'ug_buyinza', name: 'Buyinza FM', primaryUrl: 'https://stream.zeno.fm/wcancipcbrevv', category: 'World & Culture', country: 'UG', language: 'lg', bitrate: 0, description: 'Luganda community radio'),
    RadioStation(id: 'ug_joyhits', name: 'Joy Hits Radio', primaryUrl: 'https://joyhits.online/joyhitshq.mp3', category: 'Music', country: 'UG', language: 'en', bitrate: 320, description: 'Positive hits and gospel'),
    RadioStation(id: 'ug_gospelkingz', name: 'Gospel Kingz', primaryUrl: 'https://stream.zeno.fm/vstzctms6rhvv', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'Gospel music hits'),
    RadioStation(id: 'ug_ksradio', name: 'KS Radio', primaryUrl: 'https://stream.zeno.fm/jkgrrfm3rlkvv', category: 'Music', country: 'UG', language: 'en', bitrate: 0, description: 'KS Radio — entertainment and music'),
  ];


  // ─── Curated Ugandan TV channels ────────────────────────────────────────────

  static final _ugandanTvChannels = <TvChannel>[
    TvChannel(
      id: 'ntv_uganda',
      name: 'NTV Uganda',
      primaryUrl: 'https://uvotv-aniview.global.ssl.fastly.net/hls/live/2119694/ntvuganda/playlist.m3u8',
      category: 'News',
      isCustomChannel: false,
      description: 'Uganda\'s leading TV station — Nation Media Group',
      country: 'UG',
    ),
    TvChannel(
      id: 'spark_tv',
      name: 'Spark TV',
      primaryUrl: 'https://uvotv-aniview.global.ssl.fastly.net/hls/live/2119694/sparktv/playlist.m3u8',
      category: 'Entertainment',
      isCustomChannel: false,
      description: 'Ugandan entertainment, lifestyle and variety — NMG',
      country: 'UG',
    ),
    TvChannel(
      id: 'kstv_uganda',
      name: 'KSTV Uganda',
      primaryUrl: 'https://live.esteem.africa/kstv/hls/0/stream.m3u8',
      category: 'General',
      isCustomChannel: false,
      description: 'KSTV — entertainment and lifestyle',
      country: 'UG',
    ),
    TvChannel(
      id: 'bbs_terefayina',
      name: 'BBS Terefayina',
      primaryUrl: 'https://bbstv.ug/hls/ch01/index.m3u8',
      category: 'General',
      isCustomChannel: false,
      description: 'Buganda Broadcasting Services — the voice of the kingdom',
      country: 'UG',
    ),
    TvChannel(
      id: 'rwenzori_tv',
      name: 'Rwenzori TV',
      primaryUrl: 'https://stream.rwenzoritv.com:3674/live/adminlive.m3u8',
      category: 'General',
      isCustomChannel: false,
      description: 'Rwenzori region TV — Fort Portal',
      country: 'UG',
    ),
  ];

  // ─── Fallback data ───────────────────────────────────────────────────────────

  static List<RadioStation> getFallbackRadioStations() => [
        RadioStation(
          id: 'radio_one',
          name: 'Radio One FM',
          primaryUrl: 'https://stream.zeno.fm/radio_one_ug',
          backupUrl1: 'https://backup.stream/radio_one',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/en/a/a5/Radio_One_Uganda.jpg',
          category: 'Music',
          country: 'UG',
          language: 'en',
          bitrate: 128,
          description: 'Uganda\'s #1 urban radio station',
        ),
        RadioStation(
          id: 'bbc_world',
          name: 'BBC World Service',
          primaryUrl: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
          backupUrl1: 'https://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-eieuk',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/BBC_World_Service_2019.svg/320px-BBC_World_Service_2019.svg.png',
          category: 'News & Talk',
          country: 'UK',
          language: 'en',
          bitrate: 96,
          description: 'International news and current affairs',
        ),
        ..._ugandanStations,
      ];

  static List<TvChannel> getFallbackTvChannels() => [
        ..._ugandanTvChannels,
        TvChannel(
          id: 'al_jazeera',
          name: 'Al Jazeera English',
          primaryUrl: 'https://live-hls-web-aje.getaj.net/AJE/index.m3u8',
          backupUrl1: 'https://aljazeera-eng-hd-live.5centscdn.com/live/aljazeera.stream/chunks.m3u8',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Al_Jazeera_Media_Network_Logo.svg/320px-Al_Jazeera_Media_Network_Logo.svg.png',
          category: 'News',
          country: 'QA',
          description: 'Global news with Middle East perspective',
        ),
        TvChannel(
          id: 'bloomberg_tv',
          name: 'Bloomberg TV',
          primaryUrl: 'https://bloomberg.com/media-manifest/streams/us.m3u8',
          category: 'News',
          country: 'US',
          description: 'Business and financial news',
        ),
      ];

  static const _fallbackRadioCategories = [
    'All', 'Music', 'News & Talk', 'Religious', 'World & Culture', 'Public & Community',
  ];

  static const _fallbackTvCategories = [
    'All', 'News', 'Sports', 'Entertainment', 'Music',
    'Documentary', 'Education', 'Kids', 'Movies', 'General',
  ];

}
