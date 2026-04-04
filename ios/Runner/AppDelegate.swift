import Flutter
import FirebaseCore
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    UNUserNotificationCenter.current().delegate = self
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.prasu.daily.use.cloud_sync.auto_backup",
      frequency: NSNumber(value: 20 * 60)
    )
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
