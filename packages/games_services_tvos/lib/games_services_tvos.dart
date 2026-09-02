// Copyright 2026 The FlutterTV Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// tvOS (Apple TV) implementation of `games_services`.
///
/// This package is native-only. `games_services_platform_interface` ships a
/// default `MethodChannelGamesServices` that already talks to the
/// `games_services` method channel and the `games_services.player` event
/// channel, and it is platform-agnostic Dart -- so there is no platform
/// instance for this package to swap in and no `dartPluginClass` in its
/// pubspec. What tvOS was missing is the other end of those channels, and
/// that is the Swift in `tvos/Classes/`, registered for the `tvos` platform
/// via `pluginClass`.
///
/// Consumers therefore use the upstream `package:games_services/games_services.dart`
/// API directly, exactly as on iOS. Nothing in this library is imported at
/// runtime; it exists so the package has a public Dart entry point and is
/// safe to depend on and publish.
///
/// The porter's first output vendored a copy of the whole upstream Dart API
/// here -- `Leaderboards`, `Achievements`, `Player`, `SaveGame` and their
/// models. That copy was never reachable (an app imports the upstream
/// package, not this one) and would have gone stale against it, so it was
/// removed rather than published.
library games_services_tvos;
