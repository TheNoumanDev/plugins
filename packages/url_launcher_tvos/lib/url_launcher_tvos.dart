// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [UrlLauncherPlatform] for tvOS.
///
/// tvOS has no web browser (no SafariServices/WebKit), so the in-app browser
/// modes are unsupported: [supportsMode] reports `false` for them and every
/// launch falls back to an external launch (`UIApplication.open`) — the same
/// fallback the other browser-less implementations (macOS/Windows/Linux) make.
/// The supported set is wider than theirs, though: this implementation also
/// reports `true` for [PreferredLaunchMode.externalNonBrowserApplication],
/// since it forwards `universalLinksOnly` to the host. See `PORTING_REPORT.md`.
///
/// Note: [canLaunch] maps to `UIApplication.canOpenURL`, which on tvOS can
/// return `true` for an `http(s)` URL even when no installed app will actually
/// open it. Prefer the [launchUrl] return value over gating on [canLaunch].
class UrlLauncherTvos extends UrlLauncherPlatform {
  /// Creates a new plugin implementation instance.
  UrlLauncherTvos({@visibleForTesting UrlLauncherApi? api})
    : _hostApi = api ?? UrlLauncherApi();

  final UrlLauncherApi _hostApi;

  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherTvos();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  /// Whether some installed app can handle [url] (`UIApplication.canOpenURL`).
  ///
  /// On tvOS this can return `true` for an `http(s)` URL even when nothing will
  /// open it (there is no browser), so prefer checking the [launchUrl] result.
  @override
  Future<bool> canLaunch(String url) async {
    final LaunchResult result = await _hostApi.canLaunchUrl(url);
    return _mapLaunchResult(result);
  }

  @override
  Future<void> closeWebView() {
    return _hostApi.closeSafariViewController();
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    // Deliberately ordered differently from the iOS implementation, which tests
    // `useSafariVC` first. `url_launcher`'s deprecated shim infers
    // `useSafariVC = forceSafariVC ?? isWebURL`, so for any web URL an
    // iOS-shaped order would make the `universalLinksOnly` branch unreachable
    // and silently drop the caller's flag. On iOS that is harmless because the
    // SafariVC branch honours the request in-app; tvOS has no such branch, so
    // the explicit flag must win over the inferred one.
    final PreferredLaunchMode mode;
    if (universalLinksOnly) {
      mode = PreferredLaunchMode.externalNonBrowserApplication;
    } else if (useSafariVC) {
      mode = PreferredLaunchMode.inAppBrowserView;
    } else {
      mode = PreferredLaunchMode.externalApplication;
    }
    return launchUrl(
      url,
      LaunchOptions(
        mode: mode,
        webViewConfiguration: InAppWebViewConfiguration(
          enableDomStorage: enableDomStorage,
          enableJavaScript: enableJavaScript,
          headers: headers,
        ),
      ),
    );
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    // tvOS has no in-app browser: every mode falls back to an external launch,
    // the same fallback the browser-less macOS/Windows/Linux implementations
    // make (the platform interface encourages falling back over failing). An
    // unclaimed URL returns false rather than throwing.
    return _mapLaunchResult(
      await _hostApi.launchUrl(
        url,
        options.mode == PreferredLaunchMode.externalNonBrowserApplication,
      ),
    );
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async {
    switch (mode) {
      case PreferredLaunchMode.platformDefault:
      case PreferredLaunchMode.externalApplication:
      case PreferredLaunchMode.externalNonBrowserApplication:
        return true;
      // tvOS has no SafariServices/WebKit, so the in-app browser modes are
      // unavailable (unlike the iOS implementation, which supports them).
      case PreferredLaunchMode.inAppWebView:
      case PreferredLaunchMode.inAppBrowserView:
        return false;
      // Default is a desired behavior here since support for new modes is
      // always opt-in, and the enum lives in a different package, so silently
      // adding "false" for new values is the correct behavior.
      // ignore: no_default_cases, unreachable_switch_default
      default:
        return false;
    }
  }

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async {
    // No in-app browser on tvOS, so there is nothing to close for any mode.
    return false;
  }

  bool _mapLaunchResult(LaunchResult result) {
    switch (result) {
      case LaunchResult.success:
        return true;
      case LaunchResult.failure:
        return false;
      case LaunchResult.invalidUrl:
        throw _invalidUrlException();
    }
  }

  // TODO(stuartmorgan): Remove this as part of standardizing error handling.
  // See https://github.com/flutter/flutter/issues/127665
  //
  // This PlatformException (including the exact string details, since those
  // are a defacto part of the API) is for compatibility with the previous
  // native implementation.
  PlatformException _invalidUrlException() {
    throw PlatformException(
      code: 'argument_error',
      message: 'Unable to parse URL',
    );
  }
}
