import Flutter
import UIKit
import UserNotifications

public class SwiftMpushPlugin: NSObject, FlutterPlugin {
    private static var staticChannel: FlutterMethodChannel?
    private var launchNotification: [String: Any]?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mpush", binaryMessenger: registrar.messenger())
        let instance = SwiftMpushPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        staticChannel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "requestToken" {
            self.requestToken(result)
        } else if call.method == "launchNotification" {
            result(launchNotification)
        }
    }
    
    func requestToken(_ result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, _) in
                guard granted else { return }
                UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                    guard settings.authorizationStatus == .authorized else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        result(true)
                    }
                }
            }
        } else {
            result(FlutterError(code: "Unavailable for iOS < 10.0",
                                message: "Unavailable for iOS < 10.0",
                                details: nil))
        }
    }
    
    //MARK: - Application delegate
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if let userInfo = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: AnyHashable] {
            launchNotification = userInfo
        }
        return true
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let channel = SwiftMpushPlugin.staticChannel {
            let deviceTokenParts = deviceToken.map { data -> String in
                return String(format: "%02.2hhx", data)
            }
            
            let token = deviceTokenParts.joined()
            channel.invokeMethod("onToken", arguments: token, result: {(r:Any?) -> () in })
        }
    }
    
    //MARK: - Usern Notification Center Delegate
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let channel = SwiftMpushPlugin.staticChannel,
           let userInfo = notification.request.content.userInfo as? [String: AnyHashable] {
            channel.invokeMethod("pushArrived", arguments: userInfo)
        }
        completionHandler(.alert)
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let channel = SwiftMpushPlugin.staticChannel,
           let userInfo = response.notification.request.content.userInfo as? [String: AnyHashable] {
            UIApplication.shared.applicationIconBadgeNumber = 0
            channel.invokeMethod("pushTapped", arguments: userInfo)
        }
        completionHandler()
    }
}
