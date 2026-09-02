import GameKit
#if os(iOS) || os(tvOS)
import Flutter
#else
import FlutterMacOS
#endif

/// Saved games, everywhere except Apple TV.
///
/// `GKLocalPlayer`'s saved-game category -- `saveGameData(_:withName:)`,
/// `fetchSavedGames()`, `deleteSavedGames(withName:)` and
/// `resolveConflictingSavedGames(...)` -- is declared
/// `API_UNAVAILABLE(tvos, watchos)` in `GKSavedGame.h`. There is no
/// substitute API and no partial version of the feature: Game Center simply
/// does not store save data for tvOS apps, which need iCloud key-value or
/// document storage instead.
///
/// The four entry points are kept so the method channel still answers every
/// method the upstream Dart can send -- an unanswered method surfaces as a
/// `MissingPluginException`, which reads like a broken install rather than
/// an absent feature. Each returns `saved_games_unavailable` on tvOS.
class SaveGame: BaseGamesServices {
  
  func saveGame(name: String, data: String, result: @escaping FlutterResult) {
#if os(tvOS)
    result(PluginError.savedGamesUnavailable.flutterError())
#else
    log("[SaveGame] Please add the iCloud capability to your project and enable iCloud Documents. If you already have done that please ignore this message.")
    log("[SaveGame] Snapshot metadata (cover image, description, played time) is not supported by Game Center and will be ignored on iOS/macOS.")
    log("[SaveGame] Start saving game")
    guard let data = data.data(using: .utf8) else {
      log("[SaveGame] failed to get data from a string \(data)")
      result(PluginError.failedToSaveGame.flutterError)
      return
    }
    
    log("[SaveGame] Start saving the game to current player")
    currentPlayer.saveGameData(data, withName: name) { savedGame, error in
      guard error == nil else {
        log("[SaveGame] Something went wrong \(error?.localizedDescription ?? "")")
        result(error?.flutterError(code: .failedToSaveGame))
        return
      }
      
      log("[SaveGame] Saved successfully")
      result(Messages.success)
    }
#endif
  }
  
  func getSavedGames(result: @escaping FlutterResult) {
#if os(tvOS)
    result(PluginError.savedGamesUnavailable.flutterError())
#else
    log("[GetSavedGames] Please add the iCloud capability to your project and enable iCloud Documents. If you already have done that please ignore this message.")
    currentPlayer.fetchSavedGames(completionHandler: { savedGames, error in
      log("[GetSavedGames] Start loading all saved games")
      guard error == nil else {
        log("[GetSavedGames] Something went wrong \(error?.localizedDescription ?? "")")
        result(error?.flutterError(code: .failedToGetSavedGames))
        return
      }
      let items = savedGames?
        .map({ SavedGame(name: $0.name ?? "",
                         modificationDate: UInt64($0.modificationDate?.timeIntervalSince1970 ?? 0),
                         deviceName: $0.deviceName ?? "") }) ?? []
      if let data = try? JSONEncoder().encode(items) {
        log("[GetSavedGames] Loaded successfully")
        let string = String(data: data, encoding: String.Encoding.utf8)
        result(string)
      } else {
        log("[GetSavedGames] Something wrong with the data \(items)")
        result(PluginError.failedToGetSavedGames.flutterError())
      }
    })
#endif
  }
  
  func loadGame(name: String, result: @escaping FlutterResult) {
#if os(tvOS)
    result(PluginError.savedGamesUnavailable.flutterError())
#else
    log("[LoadGame] Please add the iCloud capability to your project and enable iCloud Documents. If you already have done that please ignore this message.")
    log("[LoadGame] Start loading the saved games")
    currentPlayer.fetchSavedGames(completionHandler: { savedGames, error in
      log("[LoadGame] Got saved games result")
      guard error == nil else {
        log("[LoadGame] something went wrong \(error?.localizedDescription ?? "")")
        result(error?.flutterError(code: .failedToLoadGame))
        return
      }
      
      guard let item = savedGames?
        .first(where: { $0.name == name }) else {
        log("[LoadGame] Saved game not found")
        result(PluginError.failedToLoadGame.flutterError())
        return
      }
      
      log("[LoadGame] Start loading the saved game data")
      item.loadData { data, error in
        guard let data = data, error == nil else {
          log("[LoadGame] Something went wrong loading the saved game data \(error?.localizedDescription ?? "")")
          result(error?.flutterError(code: .failedToLoadGame))
          return
        }
        log("[LoadGame] Got the saved game data")
        let string = String(data: data, encoding: String.Encoding.utf8)
        result(string)
      }
    })
#endif
  }
  
  func deleteGame(name: String, result: @escaping FlutterResult) {
#if os(tvOS)
    result(PluginError.savedGamesUnavailable.flutterError())
#else
    log("[DeleteGame] Please add the iCloud capability to your project and enable iCloud Documents. If you already have done that please ignore this message.")
    log("[DeleteGame] Start deleting game")
    currentPlayer.deleteSavedGames(withName: name) { error in
      guard error == nil else {
        log("[DeleteGame] Something went wrong \(error?.localizedDescription ?? "")")
        result(error?.flutterError(code: .failedToDeleteSavedGame))
        return
      }
      log("[DeleteGame] Deleted successfully")
      result(Messages.success)
    }
#endif
  }
  
}
