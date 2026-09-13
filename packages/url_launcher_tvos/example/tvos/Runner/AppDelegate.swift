import UIKit
import Flutter

@main
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let flutterViewController = FlutterViewController(project: nil, nibName: nil, bundle: nil)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = flutterViewController
        window.makeKeyAndVisible()
        self.window = window

        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // When the example launches its own `ullauncherdemo://` scheme, tvOS delivers
    // the URL back here — showing UIApplication.open() genuinely hands off.
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        NSLog("url_launcher_tvos example opened via URL: \(url.absoluteString)")
        return true
    }
}
