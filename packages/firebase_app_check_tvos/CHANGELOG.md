## 0.0.2

* Regenerated the Pigeon messages against `firebase_app_check` 0.4.7: `activate()`
  takes a 5th `recaptchaSiteKey` argument and the `getTokenResult` channel is
  implemented.
* Requires `firebase_app_check` `>=0.4.7 <0.4.8`.

## 0.0.1

* Initial tvOS (Apple TV) implementation of `firebase_app_check`, ported from
  `firebase_app_check` 0.4.5 with `flutter-tvos plugin port` and finished by
  hand. DeviceCheck and App Attest providers (tvOS 15+) plus the Debug provider;
  the reCAPTCHA provider is not available on tvOS (iOS-only in the Firebase Apple
  SDK).
* Native code aligned to the `firebase_core 4.11.x` /
  `firebase_core_platform_interface 7.1.0` FlutterFire train; depends on
  `firebase_core_tvos`.
