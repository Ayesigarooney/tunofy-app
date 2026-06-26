# Tunofy — Unified Streaming Hub

A high-performance Flutter app for live TV, FM Radio, Movies (TMDB), and News.
Zero sign-up. Instant playback. Offline-first favorites. Background audio with hardware controls.

---

## Features

- **Radio** — 200+ Ugandan and international FM stations via radio-browser.info
- **TV** — 1000+ IPTV channels from iptv-org with M3U parsing
- **Movies** — Browse trending, action, documentary, and African cinema via TMDB
- **News** — RSS feeds from BBC Africa, The Guardian Africa, Daily Monitor
- **Background audio** — `just_audio` + `audio_service` for lock-screen controls
- **Favorites** — Hive-persisted across radio and TV
- **Offline mode** — Cached stations/channels served when disconnected with visual indicator
- **Recording** — Capture radio snippets to device storage
- **Home widget** — Android home screen "Now Playing" widget
- **Skeleton loading** — Shimmer placeholders on every tab while content loads
- **Search** — Search radio stations by name from radio-browser.info
- **Playlist server** — Embedded Shelf HTTP server to share playlist data on LAN (opt-in)
- **Low-data mode** — Reduces bandwidth when enabled

---

## Architecture

```
lib/
├── core/
│   ├── constants/        # AppConstants, EnvConfig (API keys, URLs)
│   ├── security/         # HiveEncryption (AES-256 for local data)
│   ├── services/         # PlaylistServer, HomeWidget, Notifications
│   ├── theme/            # AppTheme, AppColors
│   └── utils/            # RecordingUtils, ShareUtils
├── data/
│   ├── models/           # RadioStation, TvChannel, Movie, NewsArticle, PlayerState
│   ├── repositories/     # Stations, Favorites, Settings (Hive-backed)
│   └── services/         # AudioPlayer, ChannelService, RadioBrowser, RSS, TMDB
└── presentation/
    ├── providers/        # Riverpod providers (state management)
    ├── screens/
    │   ├── main_shell.dart  # Shell, bottom nav, SplashScreen
    │   ├── radio/        # RadioScreen with category filter + search
    │   ├── tv/           # TvScreen with M3U channels + media_kit player
    │   ├── movies/       # MoviesScreen (TMDB integration)
    │   └── news/         # NewsScreen with built-in WebView reader
    └── widgets/          # StationCard, MiniPlayer, CategoryChips, Skeleton loaders
```

**State management:** Riverpod (FutureProvider + StateProvider)
**Audio:** `just_audio` + `audio_service` (foreground service, lock-screen controls)
**Video:** `media_kit` (ExoPlayer on Android, AVPlayer on iOS)
**Storage:** Hive with AES-256 encryption
**Networking:** Dio with timeouts & error logging

---

## Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.0.0 |
| Dart SDK | ≥ 3.0.0 |
| Android Studio / Xcode | Latest stable |

### Install

```bash
git clone <repo-url>
cd tunofy
flutter pub get
```

### Configure API Keys

Set via `--dart-define` at build time:

| Key | Source | Default |
|-----|--------|---------|
| `TMDB_API_KEY` | https://themoviedb.org/settings/api | `YOUR_TMDB_API_KEY` |
| `YOUTUBE_API_KEY` | https://console.cloud.google.com | `YOUR_YOUTUBE_API_KEY` |
| `SERVER_PORT` | (optional) | `0` (disabled) |
| `BACKEND_URL` | (optional) | `""` |

### Run

```bash
flutter run --dart-define=TMDB_API_KEY=xxx --dart-define=YOUTUBE_API_KEY=yyy
```

For release:
```bash
flutter build apk --split-per-abi --dart-define=TMDB_API_KEY=xxx --dart-define=YOUTUBE_API_KEY=yyy
```

---

## Offline Mode

When the network is unavailable, Tunofy serves stations/channels from its most recent
Hive cache. A red "Offline — showing cached stations" banner appears at the top of
the screen. All tabs gracefully degrade with cached data instead of showing empty states.

---

## Playlist Server (optional)

Tunofy includes an embedded Dart Shelf HTTP server for serving radio/TV data on LAN.
Enable it by setting `SERVER_PORT` via `--dart-define`:

```bash
flutter run --dart-define=SERVER_PORT=8080
```

A standalone backend (`server/`) is also available for custom playlist management:

```bash
cd server
dart run bin/server.dart
```

When `BACKEND_URL` is configured, the app fetches data from the backend instead of public APIs.

---

## Adding Stations / Channels

Edit `lib/data/repositories/stations_repository.dart`:

```dart
RadioStation(
  id: 'my_station',
  name: 'My Station FM',
  primaryUrl: 'https://stream.example.com/live',
  category: 'Music',
  country: 'UG',
  language: 'en',
  bitrate: 128,
  description: 'Station tagline',
)

TvChannel(
  id: 'my_channel',
  name: 'My Channel',
  primaryUrl: 'https://example.com/stream.m3u8',
  category: 'News',
  country: 'UG',
)
```

---

## Hive Boxes

| Box | Key | Value | Purpose |
|-----|-----|-------|---------|
| `favorites` | station/channel ID | `'radio'` / `'tv'` | Starred items |
| `recently_played` | station/channel ID | type string | History |
| `settings` | setting key | dynamic | Preferences, offline cache |

---

## License

Proprietary — Tunofy App. All rights reserved.
