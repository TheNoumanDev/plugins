// Copyright 2026 The FlutterTV Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// This package is native-only -- its Dart is a documentation-only library --
/// so there is no behaviour here to unit test. What there is, is a wiring
/// contract that fails *silently*: if `pubspec.yaml` stops declaring the
/// `tvos` platform, or names a `pluginClass` that no Swift file defines, the
/// tvOS toolchain simply does not register the plugin. The app then builds
/// green, links green, and throws `MissingPluginException` at the first call.
///
/// That is not hypothetical -- it is how this port spent an afternoon. These
/// tests assert the two halves still agree.
void main() {
  final String pubspec = File('pubspec.yaml').readAsStringSync();

  test('declares the tvos platform with a plugin class', () {
    // The tvOS CLI discovers plugins by looking for exactly this key. A
    // package missing it is not an error anywhere -- it is just never seen.
    expect(pubspec, contains('platforms:'));
    expect(pubspec, contains('tvos:'));
    expect(
      RegExp(r'tvos:\s*\n\s*pluginClass:\s*(\w+)').firstMatch(pubspec)?.group(1),
      'SwiftGamesServicesPlugin',
    );
  });

  test('the declared plugin class exists in the native sources', () {
    // The name in pubspec.yaml is what the generated registrant calls. If it
    // does not match the Swift, the failure is a link error at best and a
    // no-op registration at worst.
    final String plugin =
        File('tvos/Classes/SwiftGamesServicesPlugin.swift').readAsStringSync();
    expect(plugin, contains('class SwiftGamesServicesPlugin'));
    expect(plugin, contains('FlutterPlugin'));
    expect(plugin, contains('register(with registrar:'));
  });

  test('answers the channel the upstream platform interface talks to', () {
    // Federation here is nothing but a shared string: the upstream Dart sends
    // on `games_services`, and this native side has to be listening on the
    // same name. A mismatch is a MissingPluginException, not a build failure.
    final String plugin =
        File('tvos/Classes/SwiftGamesServicesPlugin.swift').readAsStringSync();
    expect(plugin, contains('"games_services"'));
  });

  test('saved games are compiled out rather than left unanswered', () {
    // GKLocalPlayer's saved-game category is API_UNAVAILABLE(tvos). The four
    // methods must still answer -- an unanswered method reads to the caller
    // as a broken install rather than an absent feature -- so the guard has
    // to return an error, not drop through.
    final String saveGame =
        File('tvos/Classes/SaveGame.swift').readAsStringSync();
    expect(saveGame, contains('#if os(tvOS)'));
    expect(saveGame, contains('savedGamesUnavailable'));
    // One guard per entry point: saveGame, getSavedGames, loadGame, deleteGame.
    expect('#if os(tvOS)'.allMatches(saveGame).length, 4);

    final String error = File('tvos/Classes/Util/Error.swift').readAsStringSync();
    expect(error, contains('case savedGamesUnavailable'));
  });
}
