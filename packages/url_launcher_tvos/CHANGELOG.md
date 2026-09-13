## 0.0.1

* Initial tvOS implementation of `url_launcher`, ported from `url_launcher_ios`
  6.4.1. External launches (`launchUrl`) and `canLaunchUrl` work via
  `UIApplication.open` / `canOpenURL`. The in-app browser modes
  (`inAppBrowserView` / `inAppWebView`) are unsupported on tvOS
  (no SafariServices): `supportsMode` reports `false`, and a launch requested
  with an in-app mode falls back to an external launch (the same fallback the
  browser-less macOS/Windows/Linux implementations make) rather than throwing.
  Unlike those three, `supportsMode` also reports `true` for
  `externalNonBrowserApplication`, since `universalLinksOnly` is forwarded to the host.
