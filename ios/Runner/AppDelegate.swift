import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // AirPlay support using AVRoutePickerView (iOS 11+)
    if #available(iOS 11.0, *) {
        let routePickerView = AVRoutePickerView(frame: CGRect(x: 20, y: 50, width: 44, height: 44))
        routePickerView.activeTintColor = UIColor.systemBlue
        routePickerView.tintColor = UIColor.gray
        window?.rootViewController?.view.addSubview(routePickerView)
    }

    // Chromecast support using Google Cast SDK
    // (Ensure your project is configured with the Google Cast SDK)
    let castButton = GCKUICastButton(frame: CGRect(x: (window?.rootViewController?.view.frame.width ?? 0) - 64, y: 50, width: 44, height: 44))
    castButton.tintColor = UIColor.white
    window?.rootViewController?.view.addSubview(castButton)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
