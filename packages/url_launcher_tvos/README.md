# url_launcher_tvos

The tvOS implementation of [`url_launcher`](https://pub.dev/packages/url_launcher).

> Ported with [`flutter-tvos plugin port`](https://github.com/fluttertv/flutter-tvos)
> from `url_launcher_ios` 6.4.1, then finished + verified by hand. See
> `PORTING_REPORT.md`.

## Usage

Federated plugin implementation — no imports needed from app code; it registers
automatically. `url_launcher` does not endorse a tvOS implementation, so add this
package **explicitly** alongside it:

```yaml
dependencies:
    url_launcher: ^6.3.2
    url_launcher_tvos: ^0.0.1
```

Then use the `url_launcher` API as usual — but not every call behaves as it does
on iOS. There is no browser on tvOS, so the in-app browser modes fall back to an
external launch and `canLaunchUrl` can return `true` for a web URL nothing will
open. See the table below before porting an iOS app over.

## What works on tvOS — and what doesn't

tvOS has **no web browser** (no SafariServices / WebKit), so this
implementation supports only the _external_ launch surface:

| Capability                                                       | tvOS          | Notes                                                                                                                                                                                                 |
| ---------------------------------------------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `canLaunchUrl`                                                   | ✅            | maps to `UIApplication.canOpenURL`                                                                                                                                                                    |
| `launchUrl` (external / universal link / app scheme)             | ✅            | maps to `UIApplication.open`; opens another installed app                                                                                                                                             |
| `launchUrl` in-app browser (`inAppBrowserView` / `inAppWebView`) | ⚠️ falls back | no `SFSafariViewController` on tvOS — `supportsMode` returns `false`, and a launch requested with an in-app mode **falls back to an external launch** (the same fallback macOS/Windows/Linux make) rather than throwing |
| `closeWebView`                                                   | ❌ (no-op)    | nothing to close — there is no in-app browser                                                                                                                                                         |

Because there is no browser, a plain `http(s)` URL only opens if another
installed app claims it (universal link / app URL scheme). Note that on tvOS
`canLaunchUrl` can return `true` for a web URL even when nothing will actually
handle it, so rely on the boolean returned by `launchUrl` rather than gating on
`canLaunchUrl` alone. **Every** launch mode — `platformDefault`, and the in-app
browser modes — resolves to an **external** launch on tvOS (the iOS
implementation opens web URLs in-app instead).

## Status

| Platform                                | Implemented | Verified                                                                                                                                                                                                                                                 |
| --------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Apple TV simulator (`appletvsimulator`) | yes         | ✅ builds (arm64); on a running Apple TV 4K sim all four channels round-trip (no `MissingPluginException`), **and a real external launch of a registered app URL scheme returns `true` and is delivered to the target** (`UIApplication.open` hands off) |
| Apple TV (`appletvos`)                  | yes         | ✅ verified on a **physical Apple TV 4K** (release/AOT) — `launchUrl` opened the App Store (a real cross-app hand-off via `UIApplication.open`)                                                                                                          |

## License

The FlutterTV Authors under a BSD-3-Clause license. See `LICENSE` for the full text.
