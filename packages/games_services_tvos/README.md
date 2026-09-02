# games_services_tvos

tvOS implementation of [`games_services`](https://pub.dev/packages/games_services)
for [flutter-tvos](https://github.com/fluttertv/flutter-tvos).

> Hand-finished from `flutter-tvos plugin port`.
> **Verified:** registers on tvOS, and `signIn()` presents Apple's native
> Game Center screen on an Apple TV, with the result returning to Dart.
> An **authenticated** round trip — submitting a score and reading entries
> back — has not been confirmed; see [Status](#status).

## Usage

```yaml
dependencies:
  games_services: ^4.1.1   # or ^5.x
  games_services_tvos: ^0.0.1
```

Then use the upstream `package:games_services/games_services.dart` API
exactly as on iOS. This package is native-only — it registers itself and
answers the same `games_services` method channel the upstream Dart
already talks to, so nothing from it is imported.

Your tvOS Runner also needs the Game Center entitlement:

```xml
<key>com.apple.developer.game-center</key>
<true/>
```

## tvOS support

### ✅ Supported

Apple TV ships the full GameKit framework, so most of the plugin is the
iOS implementation unchanged:

- **Authentication** — `GameAuth.signIn()`, `GameAuth.isSignedIn`.
  `GKLocalPlayer.local` and the two-argument `authenticateHandler`
  (`(UIViewController?, Error?)`) both exist on tvOS, so this is the same
  code path as iOS rather than a reduced one.
- **Leaderboards** — submit, `loadLeaderboardScores`, `getPlayerScore`,
  `showLeaderboards` (the native `GKGameCenterViewController`).
- **Achievements** — unlock, load, reset, `showAchievements`.
- **Player** — id, display name, profile image. Unlike watchOS, tvOS has
  `gamePlayerID` / `teamPlayerID`, so players are stably identified.
- **Access point** — `GKAccessPoint` exists on tvOS 14+.

### ❌ Not supported on tvOS

- **Saved games** — `saveGame`, `loadGame`, `getSavedGames`,
  `deleteGame`. `GKLocalPlayer`'s saved-game category is declared
  `API_UNAVAILABLE(tvos, watchos)` in `GKSavedGame.h`: Game Center does
  not store save data for tvOS apps at all, and there is no reduced
  version of the feature to offer. Use iCloud key-value or document
  storage instead.

  The four methods still answer the channel, returning the error code
  `saved_games_unavailable`. That is deliberate: a method the native side
  simply ignores surfaces in Dart as a `MissingPluginException`, which
  reads like a broken installation rather than an absent feature.

## Status

On the Apple TV simulator the plugin registers, `GameAuth.signIn()`
reaches GameKit, and Apple's own "Welcome to Game Center" screen is
presented — so the method channel, the `authenticateHandler` callback and
the view-controller presentation all work. Declining it returns
`PlatformException(failed_to_authenticate, …)` to Dart, which is the
correct answer and not the `MissingPluginException` an unregistered
plugin would give.

The simulator has no real Game Center account, so what is **not** yet
confirmed is an *authenticated* round trip on a physical Apple TV:
submitting a score and reading entries back.

This distinction is deliberate rather than pedantic. The sibling
`games_services_watchos` authenticated cleanly and still could not read
leaderboard entries on real hardware, and nothing short of a device
signed into a live account would have shown it.

## Requirements

- tvOS 14.0+ (matching upstream `games_services`'s iOS 14.0 floor; every
  newer GameKit API used is `#available`-guarded at runtime)
- the `flutter-tvos` toolchain and engine

See `PORTING_REPORT.md` for the port detail and checklist.
