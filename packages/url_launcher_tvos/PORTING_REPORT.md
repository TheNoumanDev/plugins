# url_launcher_tvos — porting report

Ported by `flutter-tvos plugin port`, then finished + verified by hand.

Source: `url_launcher_ios` 6.4.1 (Swift, Pigeon 26). Base platform: ios.
Output: `./url_launcher_tvos`

## Summary

| Status                                                         | Count                                                                                          |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Pigeon methods kept + registered on tvOS                       | 4 (`canLaunchUrl`, `launchUrl`, `openUrlInSafariViewController`, `closeSafariViewController`)  |
| Native methods behaving as-is on tvOS                          | 2 (`canLaunchUrl`, `launchUrl`)                                                                |
| Host methods kept for conformance, never called from tvOS Dart | 2 (`openUrlInSafariViewController`, `closeSafariViewController` — Dart falls back to external) |
| Native regions disabled on tvOS                                | 1 (the entire `URLLaunchSession` — SFSafariViewController)                                     |
| tvOS build outlook                                             | ✅ compiles (arm64 simulator, verified)                                                        |

## The one tvOS-absent API

`url_launcher_ios`'s only tvOS-incompatible surface is the **in-app browser**:
`SFSafariViewController` from **SafariServices**, which does not exist on tvOS.
Everything else — `UIApplication.canOpenURL` / `open(_:options:)` — is available
on tvOS. So `canLaunchUrl` and external `launchUrl` port unchanged; only the
in-app browser path is disabled.

## Native changes

- **`messages.g.swift` (generated Pigeon) — kept verbatim** except one line: the
  import gate widened from `#if os(iOS)` to `#if os(iOS) || os(tvOS)`. The porter
  had additionally wrapped `UrlLauncherApiSetup.setUp` in `#if !os(tvOS)` (it
  matched the string `SFSafariViewController` inside a doc comment) — that would
  have compiled out **all** channel registration on tvOS, so every method would
  throw `MissingPluginException`. Reverted to upstream so all four channels
  register.
- **`URLLaunchSession.swift`** — the whole class (`SFSafariViewControllerDelegate`
    - `import SafariServices`) is wrapped in `#if !os(tvOS)`; it is never referenced
      on tvOS.
- **`URLLauncherPlugin.swift`** — all four `UrlLauncherApi` methods are
  implemented (protocol conformance intact). `canLaunchUrl` / `launchUrl` are
  verbatim upstream. On tvOS, `openUrlInSafariViewController` returns
  `InAppLoadResult.noUI` (there is no browser UI to present) and
  `closeSafariViewController` is a no-op; the real Safari path stays under
  `#if !os(tvOS)`.
- **`ViewPresenter.swift`, `Launcher.swift`** — verbatim upstream; both are pure
  UIKit / `UIApplication` and compile on tvOS unchanged.

## Dart changes

This package's Dart runs **only on tvOS**, so it states tvOS behaviour directly
(no platform guards). The class is renamed `UrlLauncherIOS` → `UrlLauncherTvos`
(the `dartPluginClass` follows). The Pigeon-generated `messages.g.dart` is kept
**byte-identical to upstream 6.4.1**. The tvOS-honest behaviour:

- `supportsMode(inAppBrowserView` / `inAppWebView)` → `false` (was `true`);
  `supportsCloseForMode(...)` → `false` (nothing to close).
- **`launchUrl` falls back to an external launch for _every_ mode** (external,
  `platformDefault`, in-app) — the same fallback the browser-less
  macOS/Windows/Linux impls make. The _supported set_ is not the same as theirs:
  they report `supportsMode` `true` only for `platformDefault` and
  `externalApplication`, whereas this package also reports `true` for
  `externalNonBrowserApplication`, because it really does forward
  `universalLinksOnly` to the host. The fallback keeps the deprecated
  `launch('https://…')` — which infers an in-app mode from the URL scheme — from
  throwing: it launches externally and an unclaimed URL returns `false`. The
  in-app host methods stay registered for conformance but are unused on tvOS.
- The deprecated `launch()` override tests `universalLinksOnly` **before**
  `useSafariVC`, the reverse of iOS. The shim infers
  `useSafariVC = forceSafariVC ?? isWebURL`, so an iOS-shaped order leaves the
  `universalLinksOnly` branch unreachable for web URLs and forwards the wrong
  flag; iOS gets away with it because its SafariVC branch honours the request
  in-app, and tvOS has no such branch.

## Packaging

- Podspec: no Flutter CocoaPod dependency (resolved via `FRAMEWORK_SEARCH_PATHS`);
  `s.platform = :tvos, '13.0'` (mirrors upstream's iOS 13 floor); privacy manifest
  shipped as a `resource_bundles` entry.
- Ships **both** a podspec (CocoaPods) and `tvos/Package.swift` (Swift Package
  Manager — the Flutter 3.44 default), matching the repo's other pure-Swift
  method-channel `_tvos` plugins (e.g. `shared_preferences_tvos`). flutter-tvos's
  Podfile skips SPM-owned plugins, so the two never double-link.
- **Version floor:** the package keeps the repo-standard `flutter: >=3.13.0`, not
  upstream 6.4.1's `>=3.38.0` / Dart 3.10 (raised in 6.4.0). Nothing in this tvOS
  slice uses an API that needs the higher floor — the port builds and `dart
analyze`s clean under it — and `>=3.13.0` keeps it consistent with the sibling
  `_tvos` packages.

## Verification

- `dart analyze` clean; `flutter test` — **11/11 pass**, including a `_FakeApi`
  that asserts every mode (external, `platformDefault`, in-app, deprecated
  `launch()`) reaches the external channel and never throws.
- **`flutter-tvos build tvos --simulator`** — Xcode build succeeds (arm64), via
  both the CocoaPods and SPM paths.
- **Runtime on an Apple TV 4K simulator** — all four channels round-trip with no
  `MissingPluginException`; `canLaunchUrl(web)` returns `true` while `launchUrl`
  returns `false`, so `canLaunchUrl` isn't a reliable gate (documented in README).
- **Real cross-app launch, two ways** (throwaway targets, not shipped): on the
  sim the example launched a second app via `targetapp://` (its `AppDelegate`
  logged the delivered URL); on a **physical Apple TV 4K** (release/AOT,
  `devicectl`) `launchUrl` opened the **App Store**. `UIApplication.open`
  genuinely hands off on tvOS.

## Checklist

- [x] All Pigeon methods kept and registered on tvOS (no `MissingPluginException`).
- [x] tvOS-absent API (`SFSafariViewController`) disabled behind `#if !os(tvOS)`;
      the two affected handlers return an honest result rather than crashing.
- [x] Generated files (`messages.g.dart`, `messages.g.swift`) match upstream
      (the Swift file differs only by the import gate).
- [x] `flutter-tvos build tvos --simulator` compiles the example.
- [x] Version set (`0.0.1`) and `CHANGELOG.md` updated.
