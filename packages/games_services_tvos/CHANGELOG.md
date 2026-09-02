## 0.0.1

Initial release: tvOS implementation of `games_services`, ported from the
shared `darwin/` source of `games_services` 5.3.0.

- Authentication, leaderboards, achievements, player and access point are
  the iOS code paths unchanged — Apple TV ships the whole of GameKit.
- Saved games are compiled out and return `saved_games_unavailable`:
  `GKLocalPlayer`'s saved-game category is `API_UNAVAILABLE(tvos)`.
- Federates against `games_services_platform_interface >=4.1.1 <6.0.0`.
  The native side answers both protocol versions: same channel name,
  5.3.0's method set is a superset of 4.1.1's, and the only added
  argument (`ignoreImages`) defaults to 4.x's behaviour when absent.
