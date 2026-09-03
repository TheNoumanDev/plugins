# games_services_tvos

tvOS implementation of [`games_services`](https://pub.dev/packages/games_services)
for [flutter-tvos](https://github.com/fluttertv/flutter-tvos).

> Hand-finished from `flutter-tvos plugin port`.
> **Verified on a physical Apple TV** signed into Game Center: authentication
> resolves a named player, a score submits, and the leaderboard reads back.
> See [Status](#status).

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
  reads like a broken installation rather than an absent feature. All
  four have been called on an Apple TV and observed returning it.

## Using this with `games_services` 4.x

The Swift here is ported from `games_services` **5.3.0** and implements
5.x's behaviour, including one difference that will silently cost you a
feature if you are still on 4.x.

**`signIn()` resolves with a message on success, not `null`.**

| | success | failure |
|---|---|---|
| 4.x native (iOS, macOS) | `null` | throws `PlatformException` |
| **5.x native, and this package** | `"Player authenticated successfully"` | throws `PlatformException` |

App code written against 4.x commonly reads that as
`final error = await GameAuth.signIn(); if (error == null) { ... }` —
which on Apple TV treats a *successful* sign-in as a failure. Nothing
errors, nothing logs; the Game Center feature simply never switches on,
while every call behind it works perfectly.

Failure arrives as a **thrown** `PlatformException` on both iOS and
tvOS, so the reliable test is whether the call completed:

```dart
try {
  await GameAuth.signIn();
  // Reaching here means authenticated. The String is informational --
  // null on 4.x, a message on 5.x -- and is not a success signal.
  setState(() => gameCenterReady = true);
} on PlatformException {
  // Genuinely not signed in.
}
```

Be aware that `games_services_watchos`, if you also target the wrist,
inverts this: it reports failure by *returning* a message rather than
throwing, so there `null` really does mean success. Three
implementations, three conventions.

This is the reason the dependency range is
`games_services_platform_interface >=4.1.1 <6.0.0` rather than `^5.3.0`.
The wire protocol is compatible in both directions — same channel, and
5.3.0's method set is a superset of 4.1.1's with every argument key
unchanged — so pinning 5.x would force an upgrade on apps that cannot
take one (`games_services_watchos` pins `^4.1.1`, and a narrower range
here would stop the wrist and the TV coexisting at all). The return
value is the one place the two versions differ in a way app code can
notice, so it is documented rather than hidden behind a constraint.

## Status

On the Apple TV simulator the plugin registers, `GameAuth.signIn()`
reaches GameKit, and Apple's own "Welcome to Game Center" screen is
presented — so the method channel, the `authenticateHandler` callback and
the view-controller presentation all work. Declining it returns
`PlatformException(failed_to_authenticate, …)` to Dart, which is the
correct answer and not the `MissingPluginException` an unregistered
plugin would give.

On a **physical Apple TV** (tvOS 26.6) signed into Game Center, every
call was driven from Dart:

| call | result |
|---|---|
| `GameAuth.isSignedIn` | `true` |
| `Player.getPlayerName()` | the account's real alias |
| `Player.getPlayerID()` | a `gamePlayerID` |
| `SaveGame.*` | `saved_games_unavailable` |
| `GamesServices.submitScore` | `Success` |
| `Leaderboards.loadLeaderboardScores` | entry data |
| `Player.getPlayerScore` | the player's existing best |

The first two rows are the ones worth dwelling on. The watchOS sibling
authenticates and then *cannot read*: `GKLocalPlayer` reports an
authenticated player whose alias never resolves, and GameKit refuses
every read that follows. tvOS does not reproduce it — the alias resolves
to a real name and a real `gamePlayerID`, which is precisely the API
declared `API_UNAVAILABLE(watchos)` and whose absence forced that plugin
to identify the local player by leaderboard rank instead.

A development-signed build talks to Game Center's **sandbox**, so the
scores above are sandbox scores, not the live board.

This distinction is deliberate rather than pedantic. The sibling
`games_services_watchos` authenticated cleanly and still could not read
leaderboard entries on real hardware, and nothing short of a device
signed into a live account would have shown it.

## Requirements

- tvOS 14.0+ (matching upstream `games_services`'s iOS 14.0 floor; every
  newer GameKit API used is `#available`-guarded at runtime)
- the `flutter-tvos` toolchain and engine

See `PORTING_REPORT.md` for the port detail and checklist.
