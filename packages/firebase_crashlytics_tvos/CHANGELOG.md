## 0.0.2

* Re-ported from `firebase_crashlytics` 5.3.0 (Swift + Pigeon). With 0.0.1,
  every call failed with `channel-error` on 5.3.0.
* `pluginClass` is now `FirebaseCrashlyticsPlugin`.
* Requires `firebase_crashlytics` `^5.3.0` and `firebase_core_tvos` `^0.0.3`.
* Registers with Firebase as upstream's `flutter-fire-cls` instead of
  `flutter-fire-cls-tvos`, like the other Swift ports.

## 0.0.1

* Initial tvOS (Apple TV) implementation of `firebase_crashlytics`, ported from
  `firebase_crashlytics` 5.2.4 via `flutter-tvos plugin port` and finished by
  hand (podspec `Firebase/Crashlytics` + `firebase_core_tvos` deps, tvOS 15.0
  floor, `LIBRARY_NAME`/`LIBRARY_VERSION` defines, `firebase_core_tvos` imports,
  Dart re-export).
* No tvOS feature disables — full Crashlytics API. Compiles + links + registers
  on the tvOS simulator and device (arm64).
